import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set budgets by code.
    protocol OrderSetBudgetStore {
        func find(_ code: String) -> OrderSetBudget?
        func save(_ item: OrderSetBudget)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetBudgetStore: OrderSetBudgetStore {
        var items: [String: OrderSetBudget]
        var order: [String]

        init(items: [String: OrderSetBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetBudget) {
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

        func list() -> [OrderSetBudget] {
            var out: [OrderSetBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetBudgetStore() -> any OrderSetBudgetStore {
        return MemoryOrderSetBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetBudgetStore: OrderSetBudgetStore {
        var inner: MemoryOrderSetBudgetStore
        var cache: TTLCache<OrderSetBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetBudgetStore, cache: TTLCache<OrderSetBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetBudget? {
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

        func save(_ item: OrderSetBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetBudget] {
            return inner.list()
        }
    }

    static func newCachedOrderSetBudgetStore(_ inner: MemoryOrderSetBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetBudgetStore {
        return CachedOrderSetBudgetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set budgets. Empty fields match all.
    final class OrderSetBudgetQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetBudget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetBudget]) -> [OrderSetBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetBudgets(_ store: any OrderSetBudgetStore, query: OrderSetBudgetQuery) -> [OrderSetBudget] {
        return query.apply(store.list())
    }
}
