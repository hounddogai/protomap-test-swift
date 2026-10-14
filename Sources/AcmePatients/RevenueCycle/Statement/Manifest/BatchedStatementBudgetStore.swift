import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched statement budgets by code.
    protocol BatchedStatementBudgetStore {
        func find(_ code: String) -> BatchedStatementBudget?
        func save(_ item: BatchedStatementBudget)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedStatementBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedStatementBudgetStore: BatchedStatementBudgetStore {
        var items: [String: BatchedStatementBudget]
        var order: [String]

        init(items: [String: BatchedStatementBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedStatementBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedStatementBudget) {
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

        func list() -> [BatchedStatementBudget] {
            var out: [BatchedStatementBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedStatementBudgetStore() -> any BatchedStatementBudgetStore {
        return MemoryBatchedStatementBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedStatementBudgetStore: BatchedStatementBudgetStore {
        var inner: MemoryBatchedStatementBudgetStore
        var cache: TTLCache<BatchedStatementBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedStatementBudgetStore, cache: TTLCache<BatchedStatementBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedStatementBudget? {
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

        func save(_ item: BatchedStatementBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedStatementBudget] {
            return inner.list()
        }
    }

    static func newCachedBatchedStatementBudgetStore(_ inner: MemoryBatchedStatementBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedStatementBudgetStore {
        return CachedBatchedStatementBudgetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched statement budgets. Empty fields match all.
    final class BatchedStatementBudgetQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedStatementBudget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedStatementBudget]) -> [BatchedStatementBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedStatementBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedStatementBudgets(_ store: any BatchedStatementBudgetStore, query: BatchedStatementBudgetQuery) -> [BatchedStatementBudget] {
        return query.apply(store.list())
    }
}
