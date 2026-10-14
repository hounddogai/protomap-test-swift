import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched care gap digests by code.
    protocol BatchedCareGapDigestStore {
        func find(_ code: String) -> BatchedCareGapDigest?
        func save(_ item: BatchedCareGapDigest)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCareGapDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCareGapDigestStore: BatchedCareGapDigestStore {
        var items: [String: BatchedCareGapDigest]
        var order: [String]

        init(items: [String: BatchedCareGapDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCareGapDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCareGapDigest) {
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

        func list() -> [BatchedCareGapDigest] {
            var out: [BatchedCareGapDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCareGapDigestStore() -> any BatchedCareGapDigestStore {
        return MemoryBatchedCareGapDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCareGapDigestStore: BatchedCareGapDigestStore {
        var inner: MemoryBatchedCareGapDigestStore
        var cache: TTLCache<BatchedCareGapDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCareGapDigestStore, cache: TTLCache<BatchedCareGapDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCareGapDigest? {
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

        func save(_ item: BatchedCareGapDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCareGapDigest] {
            return inner.list()
        }
    }

    static func newCachedBatchedCareGapDigestStore(_ inner: MemoryBatchedCareGapDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCareGapDigestStore {
        return CachedBatchedCareGapDigestStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched care gap digests. Empty fields match all.
    final class BatchedCareGapDigestQuery {
        var ward: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCareGapDigest) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedCareGapDigest]) -> [BatchedCareGapDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCareGapDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCareGapDigests(_ store: any BatchedCareGapDigestStore, query: BatchedCareGapDigestQuery) -> [BatchedCareGapDigest] {
        return query.apply(store.list())
    }
}
