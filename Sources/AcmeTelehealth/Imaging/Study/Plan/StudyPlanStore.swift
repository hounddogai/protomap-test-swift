import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps study plans by code.
    protocol StudyPlanStore {
        func find(_ code: String) -> StudyPlan?
        func save(_ item: StudyPlan)
        func remove(_ code: String) -> Bool
        func list() -> [StudyPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStudyPlanStore: StudyPlanStore {
        var items: [String: StudyPlan]
        var order: [String]

        init(items: [String: StudyPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StudyPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StudyPlan) {
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

        func list() -> [StudyPlan] {
            var out: [StudyPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStudyPlanStore() -> any StudyPlanStore {
        return MemoryStudyPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStudyPlanStore: StudyPlanStore {
        var inner: MemoryStudyPlanStore
        var cache: TTLCache<StudyPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryStudyPlanStore, cache: TTLCache<StudyPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StudyPlan? {
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

        func save(_ item: StudyPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StudyPlan] {
            return inner.list()
        }
    }

    static func newCachedStudyPlanStore(_ inner: MemoryStudyPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StudyPlanStore {
        return CachedStudyPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects study plans. Empty fields match all.
    final class StudyPlanQuery {
        var region: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCost: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StudyPlan) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StudyPlan]) -> [StudyPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StudyPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStudyPlans(_ store: any StudyPlanStore, query: StudyPlanQuery) -> [StudyPlan] {
        return query.apply(store.list())
    }
}
