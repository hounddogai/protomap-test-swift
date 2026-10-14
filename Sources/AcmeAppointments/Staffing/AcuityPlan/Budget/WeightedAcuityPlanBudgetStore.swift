import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps weighted acuity plan budgets by code.
    protocol WeightedAcuityPlanBudgetStore {
        func find(_ code: String) -> WeightedAcuityPlanBudget?
        func save(_ item: WeightedAcuityPlanBudget)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedAcuityPlanBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedAcuityPlanBudgetStore: WeightedAcuityPlanBudgetStore {
        var items: [String: WeightedAcuityPlanBudget]
        var order: [String]

        init(items: [String: WeightedAcuityPlanBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedAcuityPlanBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedAcuityPlanBudget) {
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

        func list() -> [WeightedAcuityPlanBudget] {
            var out: [WeightedAcuityPlanBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedAcuityPlanBudgetStore() -> any WeightedAcuityPlanBudgetStore {
        return MemoryWeightedAcuityPlanBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedAcuityPlanBudgetStore: WeightedAcuityPlanBudgetStore {
        var inner: MemoryWeightedAcuityPlanBudgetStore
        var cache: TTLCache<WeightedAcuityPlanBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedAcuityPlanBudgetStore, cache: TTLCache<WeightedAcuityPlanBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedAcuityPlanBudget? {
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

        func save(_ item: WeightedAcuityPlanBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedAcuityPlanBudget] {
            return inner.list()
        }
    }

    static func newCachedWeightedAcuityPlanBudgetStore(_ inner: MemoryWeightedAcuityPlanBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedAcuityPlanBudgetStore {
        return CachedWeightedAcuityPlanBudgetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted acuity plan budgets. Empty fields match all.
    final class WeightedAcuityPlanBudgetQuery {
        var segment: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRefills: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedAcuityPlanBudget) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [WeightedAcuityPlanBudget]) -> [WeightedAcuityPlanBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedAcuityPlanBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedAcuityPlanBudgets(_ store: any WeightedAcuityPlanBudgetStore, query: WeightedAcuityPlanBudgetQuery) -> [WeightedAcuityPlanBudget] {
        return query.apply(store.list())
    }
}
