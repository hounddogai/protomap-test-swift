import AcmePlatform
import Foundation

extension Labs {
    /// Keeps batched courier batches by code.
    protocol BatchedCourierBatchStore {
        func find(_ code: String) -> BatchedCourierBatch?
        func save(_ item: BatchedCourierBatch)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCourierBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCourierBatchStore: BatchedCourierBatchStore {
        var items: [String: BatchedCourierBatch]
        var order: [String]

        init(items: [String: BatchedCourierBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCourierBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCourierBatch) {
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

        func list() -> [BatchedCourierBatch] {
            var out: [BatchedCourierBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCourierBatchStore() -> any BatchedCourierBatchStore {
        return MemoryBatchedCourierBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCourierBatchStore: BatchedCourierBatchStore {
        var inner: MemoryBatchedCourierBatchStore
        var cache: TTLCache<BatchedCourierBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCourierBatchStore, cache: TTLCache<BatchedCourierBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCourierBatch? {
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

        func save(_ item: BatchedCourierBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCourierBatch] {
            return inner.list()
        }
    }

    static func newCachedBatchedCourierBatchStore(_ inner: MemoryBatchedCourierBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCourierBatchStore {
        return CachedBatchedCourierBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched courier batches. Empty fields match all.
    final class BatchedCourierBatchQuery {
        var segment: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minLimit: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCourierBatch) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedCourierBatch]) -> [BatchedCourierBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCourierBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCourierBatches(_ store: any BatchedCourierBatchStore, query: BatchedCourierBatchQuery) -> [BatchedCourierBatch] {
        return query.apply(store.list())
    }
}
