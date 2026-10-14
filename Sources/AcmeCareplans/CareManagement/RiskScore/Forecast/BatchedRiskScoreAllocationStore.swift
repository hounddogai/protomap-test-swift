import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched risk score allocations by code.
    protocol BatchedRiskScoreAllocationStore {
        func find(_ code: String) -> BatchedRiskScoreAllocation?
        func save(_ item: BatchedRiskScoreAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedRiskScoreAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedRiskScoreAllocationStore: BatchedRiskScoreAllocationStore {
        var items: [String: BatchedRiskScoreAllocation]
        var order: [String]

        init(items: [String: BatchedRiskScoreAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedRiskScoreAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedRiskScoreAllocation) {
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

        func list() -> [BatchedRiskScoreAllocation] {
            var out: [BatchedRiskScoreAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedRiskScoreAllocationStore() -> any BatchedRiskScoreAllocationStore {
        return MemoryBatchedRiskScoreAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedRiskScoreAllocationStore: BatchedRiskScoreAllocationStore {
        var inner: MemoryBatchedRiskScoreAllocationStore
        var cache: TTLCache<BatchedRiskScoreAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedRiskScoreAllocationStore, cache: TTLCache<BatchedRiskScoreAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedRiskScoreAllocation? {
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

        func save(_ item: BatchedRiskScoreAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedRiskScoreAllocation] {
            return inner.list()
        }
    }

    static func newCachedBatchedRiskScoreAllocationStore(_ inner: MemoryBatchedRiskScoreAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedRiskScoreAllocationStore {
        return CachedBatchedRiskScoreAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched risk score allocations. Empty fields match all.
    final class BatchedRiskScoreAllocationQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedRiskScoreAllocation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedRiskScoreAllocation]) -> [BatchedRiskScoreAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedRiskScoreAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedRiskScoreAllocations(_ store: any BatchedRiskScoreAllocationStore, query: BatchedRiskScoreAllocationQuery) -> [BatchedRiskScoreAllocation] {
        return query.apply(store.list())
    }
}
