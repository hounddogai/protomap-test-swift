import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority budgets by code.
    protocol PriorityBudgetStore {
        func find(_ code: String) -> PriorityBudget?
        func save(_ item: PriorityBudget)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityBudgetStore: PriorityBudgetStore {
        var items: [String: PriorityBudget]
        var order: [String]

        init(items: [String: PriorityBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityBudget) {
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

        func list() -> [PriorityBudget] {
            var out: [PriorityBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityBudgetStore() -> any PriorityBudgetStore {
        return MemoryPriorityBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityBudgetStore: PriorityBudgetStore {
        var inner: MemoryPriorityBudgetStore
        var cache: TTLCache<PriorityBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityBudgetStore, cache: TTLCache<PriorityBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityBudget? {
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

        func save(_ item: PriorityBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityBudget] {
            return inner.list()
        }
    }

    static func newCachedPriorityBudgetStore(_ inner: MemoryPriorityBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityBudgetStore {
        return CachedPriorityBudgetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority budgets. Empty fields match all.
    final class PriorityBudgetQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityBudget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [PriorityBudget]) -> [PriorityBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityBudgets(_ store: any PriorityBudgetStore, query: PriorityBudgetQuery) -> [PriorityBudget] {
        return query.apply(store.list())
    }
}
