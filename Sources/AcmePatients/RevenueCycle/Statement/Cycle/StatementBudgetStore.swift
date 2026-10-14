import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement budgets by code.
    protocol StatementBudgetStore {
        func find(_ code: String) -> StatementBudget?
        func save(_ item: StatementBudget)
        func remove(_ code: String) -> Bool
        func list() -> [StatementBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementBudgetStore: StatementBudgetStore {
        var items: [String: StatementBudget]
        var order: [String]

        init(items: [String: StatementBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementBudget) {
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

        func list() -> [StatementBudget] {
            var out: [StatementBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementBudgetStore() -> any StatementBudgetStore {
        return MemoryStatementBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementBudgetStore: StatementBudgetStore {
        var inner: MemoryStatementBudgetStore
        var cache: TTLCache<StatementBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementBudgetStore, cache: TTLCache<StatementBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementBudget? {
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

        func save(_ item: StatementBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementBudget] {
            return inner.list()
        }
    }

    static func newCachedStatementBudgetStore(_ inner: MemoryStatementBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementBudgetStore {
        return CachedStatementBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement budgets. Empty fields match all.
    final class StatementBudgetQuery {
        var title: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRate: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementBudget) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [StatementBudget]) -> [StatementBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementBudgets(_ store: any StatementBudgetStore, query: StatementBudgetQuery) -> [StatementBudget] {
        return query.apply(store.list())
    }
}
