import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority reviews by code.
    protocol PriorityReviewStore {
        func find(_ code: String) -> PriorityReview?
        func save(_ item: PriorityReview)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityReviewStore: PriorityReviewStore {
        var items: [String: PriorityReview]
        var order: [String]

        init(items: [String: PriorityReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityReview) {
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

        func list() -> [PriorityReview] {
            var out: [PriorityReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityReviewStore() -> any PriorityReviewStore {
        return MemoryPriorityReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityReviewStore: PriorityReviewStore {
        var inner: MemoryPriorityReviewStore
        var cache: TTLCache<PriorityReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityReviewStore, cache: TTLCache<PriorityReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityReview? {
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

        func save(_ item: PriorityReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityReview] {
            return inner.list()
        }
    }

    static func newCachedPriorityReviewStore(_ inner: MemoryPriorityReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityReviewStore {
        return CachedPriorityReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority reviews. Empty fields match all.
    final class PriorityReviewQuery {
        var category: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityReview) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PriorityReview]) -> [PriorityReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityReviews(_ store: any PriorityReviewStore, query: PriorityReviewQuery) -> [PriorityReview] {
        return query.apply(store.list())
    }
}
