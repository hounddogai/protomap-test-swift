import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps weighted formulary plans by code.
    protocol WeightedFormularyPlanStore {
        func find(_ code: String) -> WeightedFormularyPlan?
        func save(_ item: WeightedFormularyPlan)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedFormularyPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedFormularyPlanStore: WeightedFormularyPlanStore {
        var items: [String: WeightedFormularyPlan]
        var order: [String]

        init(items: [String: WeightedFormularyPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedFormularyPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedFormularyPlan) {
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

        func list() -> [WeightedFormularyPlan] {
            var out: [WeightedFormularyPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedFormularyPlanStore() -> any WeightedFormularyPlanStore {
        return MemoryWeightedFormularyPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedFormularyPlanStore: WeightedFormularyPlanStore {
        var inner: MemoryWeightedFormularyPlanStore
        var cache: TTLCache<WeightedFormularyPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedFormularyPlanStore, cache: TTLCache<WeightedFormularyPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedFormularyPlan? {
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

        func save(_ item: WeightedFormularyPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedFormularyPlan] {
            return inner.list()
        }
    }

    static func newCachedWeightedFormularyPlanStore(_ inner: MemoryWeightedFormularyPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedFormularyPlanStore {
        return CachedWeightedFormularyPlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted formulary plans. Empty fields match all.
    final class WeightedFormularyPlanQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedFormularyPlan) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedFormularyPlan]) -> [WeightedFormularyPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedFormularyPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedFormularyPlans(_ store: any WeightedFormularyPlanStore, query: WeightedFormularyPlanQuery) -> [WeightedFormularyPlan] {
        return query.apply(store.list())
    }
}
