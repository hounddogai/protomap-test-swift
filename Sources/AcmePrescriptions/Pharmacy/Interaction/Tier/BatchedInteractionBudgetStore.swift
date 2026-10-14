import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps batched interaction budgets by code.
    protocol BatchedInteractionBudgetStore {
        func find(_ code: String) -> BatchedInteractionBudget?
        func save(_ item: BatchedInteractionBudget)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedInteractionBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedInteractionBudgetStore: BatchedInteractionBudgetStore {
        var items: [String: BatchedInteractionBudget]
        var order: [String]

        init(items: [String: BatchedInteractionBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedInteractionBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedInteractionBudget) {
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

        func list() -> [BatchedInteractionBudget] {
            var out: [BatchedInteractionBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedInteractionBudgetStore() -> any BatchedInteractionBudgetStore {
        return MemoryBatchedInteractionBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedInteractionBudgetStore: BatchedInteractionBudgetStore {
        var inner: MemoryBatchedInteractionBudgetStore
        var cache: TTLCache<BatchedInteractionBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedInteractionBudgetStore, cache: TTLCache<BatchedInteractionBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedInteractionBudget? {
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

        func save(_ item: BatchedInteractionBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedInteractionBudget] {
            return inner.list()
        }
    }

    static func newCachedBatchedInteractionBudgetStore(_ inner: MemoryBatchedInteractionBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedInteractionBudgetStore {
        return CachedBatchedInteractionBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched interaction budgets. Empty fields match all.
    final class BatchedInteractionBudgetQuery {
        var source: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRevision: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedInteractionBudget) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedInteractionBudget]) -> [BatchedInteractionBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedInteractionBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedInteractionBudgets(_ store: any BatchedInteractionBudgetStore, query: BatchedInteractionBudgetQuery) -> [BatchedInteractionBudget] {
        return query.apply(store.list())
    }
}
