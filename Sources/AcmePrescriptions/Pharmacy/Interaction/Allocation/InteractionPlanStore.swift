import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction plans by code.
    protocol InteractionPlanStore {
        func find(_ code: String) -> InteractionPlan?
        func save(_ item: InteractionPlan)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionPlanStore: InteractionPlanStore {
        var items: [String: InteractionPlan]
        var order: [String]

        init(items: [String: InteractionPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionPlan) {
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

        func list() -> [InteractionPlan] {
            var out: [InteractionPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionPlanStore() -> any InteractionPlanStore {
        return MemoryInteractionPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionPlanStore: InteractionPlanStore {
        var inner: MemoryInteractionPlanStore
        var cache: TTLCache<InteractionPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionPlanStore, cache: TTLCache<InteractionPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionPlan? {
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

        func save(_ item: InteractionPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionPlan] {
            return inner.list()
        }
    }

    static func newCachedInteractionPlanStore(_ inner: MemoryInteractionPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionPlanStore {
        return CachedInteractionPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction plans. Empty fields match all.
    final class InteractionPlanQuery {
        var ward: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionPlan) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionPlan]) -> [InteractionPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionPlans(_ store: any InteractionPlanStore, query: InteractionPlanQuery) -> [InteractionPlan] {
        return query.apply(store.list())
    }
}
