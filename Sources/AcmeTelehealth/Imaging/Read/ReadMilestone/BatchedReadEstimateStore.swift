import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps batched read estimates by code.
    protocol BatchedReadEstimateStore {
        func find(_ code: String) -> BatchedReadEstimate?
        func save(_ item: BatchedReadEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedReadEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedReadEstimateStore: BatchedReadEstimateStore {
        var items: [String: BatchedReadEstimate]
        var order: [String]

        init(items: [String: BatchedReadEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedReadEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedReadEstimate) {
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

        func list() -> [BatchedReadEstimate] {
            var out: [BatchedReadEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedReadEstimateStore() -> any BatchedReadEstimateStore {
        return MemoryBatchedReadEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedReadEstimateStore: BatchedReadEstimateStore {
        var inner: MemoryBatchedReadEstimateStore
        var cache: TTLCache<BatchedReadEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedReadEstimateStore, cache: TTLCache<BatchedReadEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedReadEstimate? {
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

        func save(_ item: BatchedReadEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedReadEstimate] {
            return inner.list()
        }
    }

    static func newCachedBatchedReadEstimateStore(_ inner: MemoryBatchedReadEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedReadEstimateStore {
        return CachedBatchedReadEstimateStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched read estimates. Empty fields match all.
    final class BatchedReadEstimateQuery {
        var source: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minScore: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedReadEstimate) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedReadEstimate]) -> [BatchedReadEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedReadEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedReadEstimates(_ store: any BatchedReadEstimateStore, query: BatchedReadEstimateQuery) -> [BatchedReadEstimate] {
        return query.apply(store.list())
    }
}
