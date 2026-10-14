import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps global interaction budgets by code.
    protocol GlobalInteractionBudgetStore {
        func find(_ code: String) -> GlobalInteractionBudget?
        func save(_ item: GlobalInteractionBudget)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalInteractionBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalInteractionBudgetStore: GlobalInteractionBudgetStore {
        var items: [String: GlobalInteractionBudget]
        var order: [String]

        init(items: [String: GlobalInteractionBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalInteractionBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalInteractionBudget) {
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

        func list() -> [GlobalInteractionBudget] {
            var out: [GlobalInteractionBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalInteractionBudgetStore() -> any GlobalInteractionBudgetStore {
        return MemoryGlobalInteractionBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalInteractionBudgetStore: GlobalInteractionBudgetStore {
        var inner: MemoryGlobalInteractionBudgetStore
        var cache: TTLCache<GlobalInteractionBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalInteractionBudgetStore, cache: TTLCache<GlobalInteractionBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalInteractionBudget? {
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

        func save(_ item: GlobalInteractionBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalInteractionBudget] {
            return inner.list()
        }
    }

    static func newCachedGlobalInteractionBudgetStore(_ inner: MemoryGlobalInteractionBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalInteractionBudgetStore {
        return CachedGlobalInteractionBudgetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global interaction budgets. Empty fields match all.
    final class GlobalInteractionBudgetQuery {
        var unit: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalInteractionBudget) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [GlobalInteractionBudget]) -> [GlobalInteractionBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalInteractionBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalInteractionBudgets(_ store: any GlobalInteractionBudgetStore, query: GlobalInteractionBudgetQuery) -> [GlobalInteractionBudget] {
        return query.apply(store.list())
    }
}
