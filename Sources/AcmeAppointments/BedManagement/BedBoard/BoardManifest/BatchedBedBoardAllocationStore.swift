import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched bed board allocations by code.
    protocol BatchedBedBoardAllocationStore {
        func find(_ code: String) -> BatchedBedBoardAllocation?
        func save(_ item: BatchedBedBoardAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedBedBoardAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedBedBoardAllocationStore: BatchedBedBoardAllocationStore {
        var items: [String: BatchedBedBoardAllocation]
        var order: [String]

        init(items: [String: BatchedBedBoardAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedBedBoardAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedBedBoardAllocation) {
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

        func list() -> [BatchedBedBoardAllocation] {
            var out: [BatchedBedBoardAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedBedBoardAllocationStore() -> any BatchedBedBoardAllocationStore {
        return MemoryBatchedBedBoardAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedBedBoardAllocationStore: BatchedBedBoardAllocationStore {
        var inner: MemoryBatchedBedBoardAllocationStore
        var cache: TTLCache<BatchedBedBoardAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedBedBoardAllocationStore, cache: TTLCache<BatchedBedBoardAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedBedBoardAllocation? {
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

        func save(_ item: BatchedBedBoardAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedBedBoardAllocation] {
            return inner.list()
        }
    }

    static func newCachedBatchedBedBoardAllocationStore(_ inner: MemoryBatchedBedBoardAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedBedBoardAllocationStore {
        return CachedBatchedBedBoardAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched bed board allocations. Empty fields match all.
    final class BatchedBedBoardAllocationQuery {
        var category: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedBedBoardAllocation) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedBedBoardAllocation]) -> [BatchedBedBoardAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedBedBoardAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedBedBoardAllocations(_ store: any BatchedBedBoardAllocationStore, query: BatchedBedBoardAllocationQuery) -> [BatchedBedBoardAllocation] {
        return query.apply(store.list())
    }
}
