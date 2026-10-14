import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps batched credential reviews by code.
    protocol BatchedCredentialReviewStore {
        func find(_ code: String) -> BatchedCredentialReview?
        func save(_ item: BatchedCredentialReview)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCredentialReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCredentialReviewStore: BatchedCredentialReviewStore {
        var items: [String: BatchedCredentialReview]
        var order: [String]

        init(items: [String: BatchedCredentialReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCredentialReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCredentialReview) {
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

        func list() -> [BatchedCredentialReview] {
            var out: [BatchedCredentialReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCredentialReviewStore() -> any BatchedCredentialReviewStore {
        return MemoryBatchedCredentialReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCredentialReviewStore: BatchedCredentialReviewStore {
        var inner: MemoryBatchedCredentialReviewStore
        var cache: TTLCache<BatchedCredentialReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCredentialReviewStore, cache: TTLCache<BatchedCredentialReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCredentialReview? {
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

        func save(_ item: BatchedCredentialReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCredentialReview] {
            return inner.list()
        }
    }

    static func newCachedBatchedCredentialReviewStore(_ inner: MemoryBatchedCredentialReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCredentialReviewStore {
        return CachedBatchedCredentialReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched credential reviews. Empty fields match all.
    final class BatchedCredentialReviewQuery {
        var label: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCredentialReview) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [BatchedCredentialReview]) -> [BatchedCredentialReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCredentialReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCredentialReviews(_ store: any BatchedCredentialReviewStore, query: BatchedCredentialReviewQuery) -> [BatchedCredentialReview] {
        return query.apply(store.list())
    }
}
