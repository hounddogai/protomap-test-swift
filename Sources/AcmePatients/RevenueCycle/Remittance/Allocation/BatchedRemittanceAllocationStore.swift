import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched remittance allocations by code.
    protocol BatchedRemittanceAllocationStore {
        func find(_ code: String) -> BatchedRemittanceAllocation?
        func save(_ item: BatchedRemittanceAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedRemittanceAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedRemittanceAllocationStore: BatchedRemittanceAllocationStore {
        var items: [String: BatchedRemittanceAllocation]
        var order: [String]

        init(items: [String: BatchedRemittanceAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedRemittanceAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedRemittanceAllocation) {
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

        func list() -> [BatchedRemittanceAllocation] {
            var out: [BatchedRemittanceAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedRemittanceAllocationStore() -> any BatchedRemittanceAllocationStore {
        return MemoryBatchedRemittanceAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedRemittanceAllocationStore: BatchedRemittanceAllocationStore {
        var inner: MemoryBatchedRemittanceAllocationStore
        var cache: TTLCache<BatchedRemittanceAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedRemittanceAllocationStore, cache: TTLCache<BatchedRemittanceAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedRemittanceAllocation? {
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

        func save(_ item: BatchedRemittanceAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedRemittanceAllocation] {
            return inner.list()
        }
    }

    static func newCachedBatchedRemittanceAllocationStore(_ inner: MemoryBatchedRemittanceAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedRemittanceAllocationStore {
        return CachedBatchedRemittanceAllocationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched remittance allocations. Empty fields match all.
    final class BatchedRemittanceAllocationQuery {
        var category: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minAmount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedRemittanceAllocation) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [BatchedRemittanceAllocation]) -> [BatchedRemittanceAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedRemittanceAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedRemittanceAllocations(_ store: any BatchedRemittanceAllocationStore, query: BatchedRemittanceAllocationQuery) -> [BatchedRemittanceAllocation] {
        return query.apply(store.list())
    }
}
