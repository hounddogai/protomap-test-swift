import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps batched modality reviews by code.
    protocol BatchedModalityReviewStore {
        func find(_ code: String) -> BatchedModalityReview?
        func save(_ item: BatchedModalityReview)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedModalityReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedModalityReviewStore: BatchedModalityReviewStore {
        var items: [String: BatchedModalityReview]
        var order: [String]

        init(items: [String: BatchedModalityReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedModalityReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedModalityReview) {
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

        func list() -> [BatchedModalityReview] {
            var out: [BatchedModalityReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedModalityReviewStore() -> any BatchedModalityReviewStore {
        return MemoryBatchedModalityReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedModalityReviewStore: BatchedModalityReviewStore {
        var inner: MemoryBatchedModalityReviewStore
        var cache: TTLCache<BatchedModalityReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedModalityReviewStore, cache: TTLCache<BatchedModalityReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedModalityReview? {
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

        func save(_ item: BatchedModalityReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedModalityReview] {
            return inner.list()
        }
    }

    static func newCachedBatchedModalityReviewStore(_ inner: MemoryBatchedModalityReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedModalityReviewStore {
        return CachedBatchedModalityReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched modality reviews. Empty fields match all.
    final class BatchedModalityReviewQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedModalityReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [BatchedModalityReview]) -> [BatchedModalityReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedModalityReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedModalityReviews(_ store: any BatchedModalityReviewStore, query: BatchedModalityReviewQuery) -> [BatchedModalityReview] {
        return query.apply(store.list())
    }
}
