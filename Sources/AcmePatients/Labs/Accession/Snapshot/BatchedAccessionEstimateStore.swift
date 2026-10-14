import AcmePlatform
import Foundation

extension Labs {
    /// Keeps batched accession estimates by code.
    protocol BatchedAccessionEstimateStore {
        func find(_ code: String) -> BatchedAccessionEstimate?
        func save(_ item: BatchedAccessionEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedAccessionEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedAccessionEstimateStore: BatchedAccessionEstimateStore {
        var items: [String: BatchedAccessionEstimate]
        var order: [String]

        init(items: [String: BatchedAccessionEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedAccessionEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedAccessionEstimate) {
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

        func list() -> [BatchedAccessionEstimate] {
            var out: [BatchedAccessionEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedAccessionEstimateStore() -> any BatchedAccessionEstimateStore {
        return MemoryBatchedAccessionEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedAccessionEstimateStore: BatchedAccessionEstimateStore {
        var inner: MemoryBatchedAccessionEstimateStore
        var cache: TTLCache<BatchedAccessionEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedAccessionEstimateStore, cache: TTLCache<BatchedAccessionEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedAccessionEstimate? {
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

        func save(_ item: BatchedAccessionEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedAccessionEstimate] {
            return inner.list()
        }
    }

    static func newCachedBatchedAccessionEstimateStore(_ inner: MemoryBatchedAccessionEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedAccessionEstimateStore {
        return CachedBatchedAccessionEstimateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched accession estimates. Empty fields match all.
    final class BatchedAccessionEstimateQuery {
        var country: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minRefills: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedAccessionEstimate) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedAccessionEstimate]) -> [BatchedAccessionEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedAccessionEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedAccessionEstimates(_ store: any BatchedAccessionEstimateStore, query: BatchedAccessionEstimateQuery) -> [BatchedAccessionEstimate] {
        return query.apply(store.list())
    }
}
