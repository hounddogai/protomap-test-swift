import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps batched closure estimates by code.
    protocol BatchedClosureEstimateStore {
        func find(_ code: String) -> BatchedClosureEstimate?
        func save(_ item: BatchedClosureEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedClosureEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedClosureEstimateStore: BatchedClosureEstimateStore {
        var items: [String: BatchedClosureEstimate]
        var order: [String]

        init(items: [String: BatchedClosureEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedClosureEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedClosureEstimate) {
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

        func list() -> [BatchedClosureEstimate] {
            var out: [BatchedClosureEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedClosureEstimateStore() -> any BatchedClosureEstimateStore {
        return MemoryBatchedClosureEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedClosureEstimateStore: BatchedClosureEstimateStore {
        var inner: MemoryBatchedClosureEstimateStore
        var cache: TTLCache<BatchedClosureEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedClosureEstimateStore, cache: TTLCache<BatchedClosureEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedClosureEstimate? {
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

        func save(_ item: BatchedClosureEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedClosureEstimate] {
            return inner.list()
        }
    }

    static func newCachedBatchedClosureEstimateStore(_ inner: MemoryBatchedClosureEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedClosureEstimateStore {
        return CachedBatchedClosureEstimateStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched closure estimates. Empty fields match all.
    final class BatchedClosureEstimateQuery {
        var segment: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedClosureEstimate) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedClosureEstimate]) -> [BatchedClosureEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedClosureEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedClosureEstimates(_ store: any BatchedClosureEstimateStore, query: BatchedClosureEstimateQuery) -> [BatchedClosureEstimate] {
        return query.apply(store.list())
    }
}
