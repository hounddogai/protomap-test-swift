import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set plans by code.
    protocol OrderSetPlanStore {
        func find(_ code: String) -> OrderSetPlan?
        func save(_ item: OrderSetPlan)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetPlanStore: OrderSetPlanStore {
        var items: [String: OrderSetPlan]
        var order: [String]

        init(items: [String: OrderSetPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetPlan) {
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

        func list() -> [OrderSetPlan] {
            var out: [OrderSetPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetPlanStore() -> any OrderSetPlanStore {
        return MemoryOrderSetPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetPlanStore: OrderSetPlanStore {
        var inner: MemoryOrderSetPlanStore
        var cache: TTLCache<OrderSetPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetPlanStore, cache: TTLCache<OrderSetPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetPlan? {
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

        func save(_ item: OrderSetPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetPlan] {
            return inner.list()
        }
    }

    static func newCachedOrderSetPlanStore(_ inner: MemoryOrderSetPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetPlanStore {
        return CachedOrderSetPlanStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set plans. Empty fields match all.
    final class OrderSetPlanQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetPlan]) -> [OrderSetPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetPlans(_ store: any OrderSetPlanStore, query: OrderSetPlanQuery) -> [OrderSetPlan] {
        return query.apply(store.list())
    }
}
