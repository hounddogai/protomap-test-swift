import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding plans by code.
    protocol RoundingPlanStore {
        func find(_ code: String) -> RoundingPlan?
        func save(_ item: RoundingPlan)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingPlanStore: RoundingPlanStore {
        var items: [String: RoundingPlan]
        var order: [String]

        init(items: [String: RoundingPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingPlan) {
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

        func list() -> [RoundingPlan] {
            var out: [RoundingPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingPlanStore() -> any RoundingPlanStore {
        return MemoryRoundingPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingPlanStore: RoundingPlanStore {
        var inner: MemoryRoundingPlanStore
        var cache: TTLCache<RoundingPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingPlanStore, cache: TTLCache<RoundingPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingPlan? {
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

        func save(_ item: RoundingPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingPlan] {
            return inner.list()
        }
    }

    static func newCachedRoundingPlanStore(_ inner: MemoryRoundingPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingPlanStore {
        return CachedRoundingPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding plans. Empty fields match all.
    final class RoundingPlanQuery {
        var country: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingPlan) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingPlan]) -> [RoundingPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingPlans(_ store: any RoundingPlanStore, query: RoundingPlanQuery) -> [RoundingPlan] {
        return query.apply(store.list())
    }
}
