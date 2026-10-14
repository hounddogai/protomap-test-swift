import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study policies by code.
    protocol StudyPolicyStore {
        func find(_ code: String) -> StudyPolicy?
        func save(_ item: StudyPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [StudyPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyPolicyStore: StudyPolicyStore {
        var items: [String: StudyPolicy]
        var order: [String]

        init(items: [String: StudyPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyPolicy) {
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

        func list() -> [StudyPolicy] {
            var out: [StudyPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyPolicyStore() -> any StudyPolicyStore {
        return MemoryStudyPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyPolicyStore: StudyPolicyStore {
        var inner: MemoryStudyPolicyStore
        var cache: TTLCache<StudyPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyPolicyStore, cache: TTLCache<StudyPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyPolicy? {
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

        func save(_ item: StudyPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyPolicy] {
            return inner.list()
        }
    }

    static func newCachedStudyPolicyStore(_ inner: MemoryStudyPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyPolicyStore {
        return CachedStudyPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study policies. Empty fields match all.
    final class StudyPolicyQuery {
        var region: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyPolicy) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyPolicy]) -> [StudyPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyPolicies(_ store: any StudyPolicyStore, query: StudyPolicyQuery) -> [StudyPolicy] {
        return query.apply(store.list())
    }
}
