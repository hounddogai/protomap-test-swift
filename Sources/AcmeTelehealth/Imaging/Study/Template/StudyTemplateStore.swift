import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study templates by code.
    protocol StudyTemplateStore {
        func find(_ code: String) -> StudyTemplate?
        func save(_ item: StudyTemplate)
        func remove(_ code: String) -> Bool
        func list() -> [StudyTemplate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyTemplateStore: StudyTemplateStore {
        var items: [String: StudyTemplate]
        var order: [String]

        init(items: [String: StudyTemplate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyTemplate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyTemplate) {
            if !(items[item.code] != nil) {
                order.append(item.code)
            }
            items[item.code] = item
        }

        func remove(_ code: String) -> Bool {
            if !(items[code] != nil) {
                return false
            }
            items.removeValue(forKey: code)
            var kept: [String] = []
            for existing in order {
                if existing != code {
                    kept.append(existing)
                }
            }
            order = kept
            return true
        }

        func list() -> [StudyTemplate] {
            var out: [StudyTemplate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyTemplateStore() -> any StudyTemplateStore {
        return MemoryStudyTemplateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyTemplateStore: StudyTemplateStore {
        var inner: MemoryStudyTemplateStore
        var cache: TTLCache<StudyTemplate>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyTemplateStore, cache: TTLCache<StudyTemplate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyTemplate? {
            guard let hit = cache.getValue(code) else {
                misses += 1
                guard let found = inner.find(code) else {
                    return nil
                }
                cache.put(code, value: found)
                return found
            }
            hits += 1
            return hit
        }

        func save(_ item: StudyTemplate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyTemplate] {
            return inner.list()
        }
    }

    static func newCachedStudyTemplateStore(_ inner: MemoryStudyTemplateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyTemplateStore {
        return CachedStudyTemplateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study templates. Empty fields match all.
    final class StudyTemplateQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyTemplate) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyTemplate]) -> [StudyTemplate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyTemplate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyTemplates(_ store: any StudyTemplateStore, query: StudyTemplateQuery) -> [StudyTemplate] {
        return query.apply(store.list())
    }
}
