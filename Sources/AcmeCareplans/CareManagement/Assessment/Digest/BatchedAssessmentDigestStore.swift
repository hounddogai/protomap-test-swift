import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched assessment digests by code.
    protocol BatchedAssessmentDigestStore {
        func find(_ code: String) -> BatchedAssessmentDigest?
        func save(_ item: BatchedAssessmentDigest)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedAssessmentDigest]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedAssessmentDigestStore: BatchedAssessmentDigestStore {
        var items: [String: BatchedAssessmentDigest]
        var order: [String]

        init(items: [String: BatchedAssessmentDigest], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedAssessmentDigest? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedAssessmentDigest) {
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

        func list() -> [BatchedAssessmentDigest] {
            var out: [BatchedAssessmentDigest] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedAssessmentDigestStore() -> any BatchedAssessmentDigestStore {
        return MemoryBatchedAssessmentDigestStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedAssessmentDigestStore: BatchedAssessmentDigestStore {
        var inner: MemoryBatchedAssessmentDigestStore
        var cache: TTLCache<BatchedAssessmentDigest>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedAssessmentDigestStore, cache: TTLCache<BatchedAssessmentDigest>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedAssessmentDigest? {
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

        func save(_ item: BatchedAssessmentDigest) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedAssessmentDigest] {
            return inner.list()
        }
    }

    static func newCachedBatchedAssessmentDigestStore(_ inner: MemoryBatchedAssessmentDigestStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedAssessmentDigestStore {
        return CachedBatchedAssessmentDigestStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched assessment digests. Empty fields match all.
    final class BatchedAssessmentDigestQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedAssessmentDigest) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedAssessmentDigest]) -> [BatchedAssessmentDigest] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedAssessmentDigest) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedAssessmentDigests(_ store: any BatchedAssessmentDigestStore, query: BatchedAssessmentDigestQuery) -> [BatchedAssessmentDigest] {
        return query.apply(store.list())
    }
}
