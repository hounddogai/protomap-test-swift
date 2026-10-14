import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps weighted credential plans by code.
    protocol WeightedCredentialPlanStore {
        func find(_ code: String) -> WeightedCredentialPlan?
        func save(_ item: WeightedCredentialPlan)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedCredentialPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedCredentialPlanStore: WeightedCredentialPlanStore {
        var items: [String: WeightedCredentialPlan]
        var order: [String]

        init(items: [String: WeightedCredentialPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedCredentialPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedCredentialPlan) {
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

        func list() -> [WeightedCredentialPlan] {
            var out: [WeightedCredentialPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedCredentialPlanStore() -> any WeightedCredentialPlanStore {
        return MemoryWeightedCredentialPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedCredentialPlanStore: WeightedCredentialPlanStore {
        var inner: MemoryWeightedCredentialPlanStore
        var cache: TTLCache<WeightedCredentialPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedCredentialPlanStore, cache: TTLCache<WeightedCredentialPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedCredentialPlan? {
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

        func save(_ item: WeightedCredentialPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedCredentialPlan] {
            return inner.list()
        }
    }

    static func newCachedWeightedCredentialPlanStore(_ inner: MemoryWeightedCredentialPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedCredentialPlanStore {
        return CachedWeightedCredentialPlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted credential plans. Empty fields match all.
    final class WeightedCredentialPlanQuery {
        var region: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedCredentialPlan) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedCredentialPlan]) -> [WeightedCredentialPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedCredentialPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedCredentialPlans(_ store: any WeightedCredentialPlanStore, query: WeightedCredentialPlanQuery) -> [WeightedCredentialPlan] {
        return query.apply(store.list())
    }
}
