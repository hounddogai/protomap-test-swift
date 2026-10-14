import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal budgets by code.
    protocol GoalBudgetStore {
        func find(_ code: String) -> GoalBudget?
        func save(_ item: GoalBudget)
        func remove(_ code: String) -> Bool
        func list() -> [GoalBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalBudgetStore: GoalBudgetStore {
        var items: [String: GoalBudget]
        var order: [String]

        init(items: [String: GoalBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalBudget) {
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

        func list() -> [GoalBudget] {
            var out: [GoalBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalBudgetStore() -> any GoalBudgetStore {
        return MemoryGoalBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalBudgetStore: GoalBudgetStore {
        var inner: MemoryGoalBudgetStore
        var cache: TTLCache<GoalBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalBudgetStore, cache: TTLCache<GoalBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalBudget? {
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

        func save(_ item: GoalBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalBudget] {
            return inner.list()
        }
    }

    static func newCachedGoalBudgetStore(_ inner: MemoryGoalBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalBudgetStore {
        return CachedGoalBudgetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal budgets. Empty fields match all.
    final class GoalBudgetQuery {
        var channel: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalBudget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalBudget]) -> [GoalBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalBudgets(_ store: any GoalBudgetStore, query: GoalBudgetQuery) -> [GoalBudget] {
        return query.apply(store.list())
    }
}
