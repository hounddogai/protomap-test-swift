import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps global worklist plans by code.
    protocol GlobalWorklistPlanStore {
        func find(_ code: String) -> GlobalWorklistPlan?
        func save(_ item: GlobalWorklistPlan)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalWorklistPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalWorklistPlanStore: GlobalWorklistPlanStore {
        var items: [String: GlobalWorklistPlan]
        var order: [String]

        init(items: [String: GlobalWorklistPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalWorklistPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalWorklistPlan) {
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

        func list() -> [GlobalWorklistPlan] {
            var out: [GlobalWorklistPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalWorklistPlanStore() -> any GlobalWorklistPlanStore {
        return MemoryGlobalWorklistPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalWorklistPlanStore: GlobalWorklistPlanStore {
        var inner: MemoryGlobalWorklistPlanStore
        var cache: TTLCache<GlobalWorklistPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalWorklistPlanStore, cache: TTLCache<GlobalWorklistPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalWorklistPlan? {
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

        func save(_ item: GlobalWorklistPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalWorklistPlan] {
            return inner.list()
        }
    }

    static func newCachedGlobalWorklistPlanStore(_ inner: MemoryGlobalWorklistPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalWorklistPlanStore {
        return CachedGlobalWorklistPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global worklist plans. Empty fields match all.
    final class GlobalWorklistPlanQuery {
        var label: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRatio: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalWorklistPlan) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalWorklistPlan]) -> [GlobalWorklistPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalWorklistPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalWorklistPlans(_ store: any GlobalWorklistPlanStore, query: GlobalWorklistPlanQuery) -> [GlobalWorklistPlan] {
        return query.apply(store.list())
    }
}
