import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps batched overtime allocations by code.
    protocol BatchedOvertimeAllocationStore {
        func find(_ code: String) -> BatchedOvertimeAllocation?
        func save(_ item: BatchedOvertimeAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedOvertimeAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedOvertimeAllocationStore: BatchedOvertimeAllocationStore {
        var items: [String: BatchedOvertimeAllocation]
        var order: [String]

        init(items: [String: BatchedOvertimeAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedOvertimeAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedOvertimeAllocation) {
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

        func list() -> [BatchedOvertimeAllocation] {
            var out: [BatchedOvertimeAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedOvertimeAllocationStore() -> any BatchedOvertimeAllocationStore {
        return MemoryBatchedOvertimeAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedOvertimeAllocationStore: BatchedOvertimeAllocationStore {
        var inner: MemoryBatchedOvertimeAllocationStore
        var cache: TTLCache<BatchedOvertimeAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedOvertimeAllocationStore, cache: TTLCache<BatchedOvertimeAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedOvertimeAllocation? {
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

        func save(_ item: BatchedOvertimeAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedOvertimeAllocation] {
            return inner.list()
        }
    }

    static func newCachedBatchedOvertimeAllocationStore(_ inner: MemoryBatchedOvertimeAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedOvertimeAllocationStore {
        return CachedBatchedOvertimeAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched overtime allocations. Empty fields match all.
    final class BatchedOvertimeAllocationQuery {
        var title: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedOvertimeAllocation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedOvertimeAllocation]) -> [BatchedOvertimeAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedOvertimeAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedOvertimeAllocations(_ store: any BatchedOvertimeAllocationStore, query: BatchedOvertimeAllocationQuery) -> [BatchedOvertimeAllocation] {
        return query.apply(store.list())
    }
}
