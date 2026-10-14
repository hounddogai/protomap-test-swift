import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default assessment entries by code.
    protocol DefaultAssessmentEntryStore {
        func find(_ code: String) -> DefaultAssessmentEntry?
        func save(_ item: DefaultAssessmentEntry)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultAssessmentEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultAssessmentEntryStore: DefaultAssessmentEntryStore {
        var items: [String: DefaultAssessmentEntry]
        var order: [String]

        init(items: [String: DefaultAssessmentEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultAssessmentEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultAssessmentEntry) {
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

        func list() -> [DefaultAssessmentEntry] {
            var out: [DefaultAssessmentEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultAssessmentEntryStore() -> any DefaultAssessmentEntryStore {
        return MemoryDefaultAssessmentEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultAssessmentEntryStore: DefaultAssessmentEntryStore {
        var inner: MemoryDefaultAssessmentEntryStore
        var cache: TTLCache<DefaultAssessmentEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultAssessmentEntryStore, cache: TTLCache<DefaultAssessmentEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultAssessmentEntry? {
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

        func save(_ item: DefaultAssessmentEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultAssessmentEntry] {
            return inner.list()
        }
    }

    static func newCachedDefaultAssessmentEntryStore(_ inner: MemoryDefaultAssessmentEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultAssessmentEntryStore {
        return CachedDefaultAssessmentEntryStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default assessment entries. Empty fields match all.
    final class DefaultAssessmentEntryQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultAssessmentEntry) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultAssessmentEntry]) -> [DefaultAssessmentEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultAssessmentEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultAssessmentEntries(_ store: any DefaultAssessmentEntryStore, query: DefaultAssessmentEntryQuery) -> [DefaultAssessmentEntry] {
        return query.apply(store.list())
    }
}
