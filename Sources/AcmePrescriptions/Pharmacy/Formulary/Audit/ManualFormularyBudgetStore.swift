import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual formulary budgets by code.
    protocol ManualFormularyBudgetStore {
        func find(_ code: String) -> ManualFormularyBudget?
        func save(_ item: ManualFormularyBudget)
        func remove(_ code: String) -> Bool
        func list() -> [ManualFormularyBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualFormularyBudgetStore: ManualFormularyBudgetStore {
        var items: [String: ManualFormularyBudget]
        var order: [String]

        init(items: [String: ManualFormularyBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualFormularyBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualFormularyBudget) {
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

        func list() -> [ManualFormularyBudget] {
            var out: [ManualFormularyBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualFormularyBudgetStore() -> any ManualFormularyBudgetStore {
        return MemoryManualFormularyBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualFormularyBudgetStore: ManualFormularyBudgetStore {
        var inner: MemoryManualFormularyBudgetStore
        var cache: TTLCache<ManualFormularyBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualFormularyBudgetStore, cache: TTLCache<ManualFormularyBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualFormularyBudget? {
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

        func save(_ item: ManualFormularyBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualFormularyBudget] {
            return inner.list()
        }
    }

    static func newCachedManualFormularyBudgetStore(_ inner: MemoryManualFormularyBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualFormularyBudgetStore {
        return CachedManualFormularyBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual formulary budgets. Empty fields match all.
    final class ManualFormularyBudgetQuery {
        var category: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minRate: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualFormularyBudget) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualFormularyBudget]) -> [ManualFormularyBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualFormularyBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualFormularyBudgets(_ store: any ManualFormularyBudgetStore, query: ManualFormularyBudgetQuery) -> [ManualFormularyBudget] {
        return query.apply(store.list())
    }
}
