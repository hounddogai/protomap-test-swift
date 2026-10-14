import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study bundles by code.
    protocol StudyBundleStore {
        func find(_ code: String) -> StudyBundle?
        func save(_ item: StudyBundle)
        func remove(_ code: String) -> Bool
        func list() -> [StudyBundle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyBundleStore: StudyBundleStore {
        var items: [String: StudyBundle]
        var order: [String]

        init(items: [String: StudyBundle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyBundle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyBundle) {
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

        func list() -> [StudyBundle] {
            var out: [StudyBundle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyBundleStore() -> any StudyBundleStore {
        return MemoryStudyBundleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyBundleStore: StudyBundleStore {
        var inner: MemoryStudyBundleStore
        var cache: TTLCache<StudyBundle>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyBundleStore, cache: TTLCache<StudyBundle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyBundle? {
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

        func save(_ item: StudyBundle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyBundle] {
            return inner.list()
        }
    }

    static func newCachedStudyBundleStore(_ inner: MemoryStudyBundleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyBundleStore {
        return CachedStudyBundleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study bundles. Empty fields match all.
    final class StudyBundleQuery {
        var label: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRefills: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyBundle) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyBundle]) -> [StudyBundle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyBundle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyBundles(_ store: any StudyBundleStore, query: StudyBundleQuery) -> [StudyBundle] {
        return query.apply(store.list())
    }
}
