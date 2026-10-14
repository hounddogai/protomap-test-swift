import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps batched care protocol reviews by code.
    protocol BatchedCareProtocolReviewStore {
        func find(_ code: String) -> BatchedCareProtocolReview?
        func save(_ item: BatchedCareProtocolReview)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCareProtocolReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCareProtocolReviewStore: BatchedCareProtocolReviewStore {
        var items: [String: BatchedCareProtocolReview]
        var order: [String]

        init(items: [String: BatchedCareProtocolReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCareProtocolReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCareProtocolReview) {
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

        func list() -> [BatchedCareProtocolReview] {
            var out: [BatchedCareProtocolReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCareProtocolReviewStore() -> any BatchedCareProtocolReviewStore {
        return MemoryBatchedCareProtocolReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCareProtocolReviewStore: BatchedCareProtocolReviewStore {
        var inner: MemoryBatchedCareProtocolReviewStore
        var cache: TTLCache<BatchedCareProtocolReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCareProtocolReviewStore, cache: TTLCache<BatchedCareProtocolReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCareProtocolReview? {
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

        func save(_ item: BatchedCareProtocolReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCareProtocolReview] {
            return inner.list()
        }
    }

    static func newCachedBatchedCareProtocolReviewStore(_ inner: MemoryBatchedCareProtocolReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCareProtocolReviewStore {
        return CachedBatchedCareProtocolReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched care protocol reviews. Empty fields match all.
    final class BatchedCareProtocolReviewQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCareProtocolReview) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedCareProtocolReview]) -> [BatchedCareProtocolReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCareProtocolReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCareProtocolReviews(_ store: any BatchedCareProtocolReviewStore, query: BatchedCareProtocolReviewQuery) -> [BatchedCareProtocolReview] {
        return query.apply(store.list())
    }
}
