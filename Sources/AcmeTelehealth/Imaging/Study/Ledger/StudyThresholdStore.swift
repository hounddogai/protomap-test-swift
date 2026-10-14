import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study thresholds by code.
    protocol StudyThresholdStore {
        func find(_ code: String) -> StudyThreshold?
        func save(_ item: StudyThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [StudyThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyThresholdStore: StudyThresholdStore {
        var items: [String: StudyThreshold]
        var order: [String]

        init(items: [String: StudyThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyThreshold) {
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

        func list() -> [StudyThreshold] {
            var out: [StudyThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyThresholdStore() -> any StudyThresholdStore {
        return MemoryStudyThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyThresholdStore: StudyThresholdStore {
        var inner: MemoryStudyThresholdStore
        var cache: TTLCache<StudyThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyThresholdStore, cache: TTLCache<StudyThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyThreshold? {
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

        func save(_ item: StudyThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyThreshold] {
            return inner.list()
        }
    }

    static func newCachedStudyThresholdStore(_ inner: MemoryStudyThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyThresholdStore {
        return CachedStudyThresholdStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study thresholds. Empty fields match all.
    final class StudyThresholdQuery {
        var region: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minPriority: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyThreshold) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyThreshold]) -> [StudyThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyThresholds(_ store: any StudyThresholdStore, query: StudyThresholdQuery) -> [StudyThreshold] {
        return query.apply(store.list())
    }
}
