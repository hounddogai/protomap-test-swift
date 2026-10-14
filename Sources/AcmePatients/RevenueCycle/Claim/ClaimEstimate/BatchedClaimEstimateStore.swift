import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched claim estimates by code.
    protocol BatchedClaimEstimateStore {
        func find(_ code: String) -> BatchedClaimEstimate?
        func save(_ item: BatchedClaimEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedClaimEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedClaimEstimateStore: BatchedClaimEstimateStore {
        var items: [String: BatchedClaimEstimate]
        var order: [String]

        init(items: [String: BatchedClaimEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedClaimEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedClaimEstimate) {
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

        func list() -> [BatchedClaimEstimate] {
            var out: [BatchedClaimEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedClaimEstimateStore() -> any BatchedClaimEstimateStore {
        return MemoryBatchedClaimEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedClaimEstimateStore: BatchedClaimEstimateStore {
        var inner: MemoryBatchedClaimEstimateStore
        var cache: TTLCache<BatchedClaimEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedClaimEstimateStore, cache: TTLCache<BatchedClaimEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedClaimEstimate? {
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

        func save(_ item: BatchedClaimEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedClaimEstimate] {
            return inner.list()
        }
    }

    static func newCachedBatchedClaimEstimateStore(_ inner: MemoryBatchedClaimEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedClaimEstimateStore {
        return CachedBatchedClaimEstimateStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched claim estimates. Empty fields match all.
    final class BatchedClaimEstimateQuery {
        var segment: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minCopay: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedClaimEstimate) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedClaimEstimate]) -> [BatchedClaimEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedClaimEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedClaimEstimates(_ store: any BatchedClaimEstimateStore, query: BatchedClaimEstimateQuery) -> [BatchedClaimEstimate] {
        return query.apply(store.list())
    }
}
