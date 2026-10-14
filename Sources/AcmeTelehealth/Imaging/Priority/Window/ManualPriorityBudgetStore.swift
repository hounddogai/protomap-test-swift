import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual priority budgets by code.
    protocol ManualPriorityBudgetStore {
        func find(_ code: String) -> ManualPriorityBudget?
        func save(_ item: ManualPriorityBudget)
        func remove(_ code: String) -> Bool
        func list() -> [ManualPriorityBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualPriorityBudgetStore: ManualPriorityBudgetStore {
        var items: [String: ManualPriorityBudget]
        var order: [String]

        init(items: [String: ManualPriorityBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualPriorityBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualPriorityBudget) {
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

        func list() -> [ManualPriorityBudget] {
            var out: [ManualPriorityBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualPriorityBudgetStore() -> any ManualPriorityBudgetStore {
        return MemoryManualPriorityBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualPriorityBudgetStore: ManualPriorityBudgetStore {
        var inner: MemoryManualPriorityBudgetStore
        var cache: TTLCache<ManualPriorityBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualPriorityBudgetStore, cache: TTLCache<ManualPriorityBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualPriorityBudget? {
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

        func save(_ item: ManualPriorityBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualPriorityBudget] {
            return inner.list()
        }
    }

    static func newCachedManualPriorityBudgetStore(_ inner: MemoryManualPriorityBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualPriorityBudgetStore {
        return CachedManualPriorityBudgetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual priority budgets. Empty fields match all.
    final class ManualPriorityBudgetQuery {
        var region: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualPriorityBudget) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [ManualPriorityBudget]) -> [ManualPriorityBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualPriorityBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualPriorityBudgets(_ store: any ManualPriorityBudgetStore, query: ManualPriorityBudgetQuery) -> [ManualPriorityBudget] {
        return query.apply(store.list())
    }
}
