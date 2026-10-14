import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps pending rounding plans by code.
    protocol PendingRoundingPlanStore {
        func find(_ code: String) -> PendingRoundingPlan?
        func save(_ item: PendingRoundingPlan)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRoundingPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRoundingPlanStore: PendingRoundingPlanStore {
        var items: [String: PendingRoundingPlan]
        var order: [String]

        init(items: [String: PendingRoundingPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRoundingPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRoundingPlan) {
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

        func list() -> [PendingRoundingPlan] {
            var out: [PendingRoundingPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRoundingPlanStore() -> any PendingRoundingPlanStore {
        return MemoryPendingRoundingPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRoundingPlanStore: PendingRoundingPlanStore {
        var inner: MemoryPendingRoundingPlanStore
        var cache: TTLCache<PendingRoundingPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRoundingPlanStore, cache: TTLCache<PendingRoundingPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRoundingPlan? {
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

        func save(_ item: PendingRoundingPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRoundingPlan] {
            return inner.list()
        }
    }

    static func newCachedPendingRoundingPlanStore(_ inner: MemoryPendingRoundingPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRoundingPlanStore {
        return CachedPendingRoundingPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending rounding plans. Empty fields match all.
    final class PendingRoundingPlanQuery {
        var unit: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRoundingPlan) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [PendingRoundingPlan]) -> [PendingRoundingPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRoundingPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRoundingPlans(_ store: any PendingRoundingPlanStore, query: PendingRoundingPlanQuery) -> [PendingRoundingPlan] {
        return query.apply(store.list())
    }
}
