import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range reviews by code.
    protocol ReferenceRangeReviewStore {
        func find(_ code: String) -> ReferenceRangeReview?
        func save(_ item: ReferenceRangeReview)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeReviewStore: ReferenceRangeReviewStore {
        var items: [String: ReferenceRangeReview]
        var order: [String]

        init(items: [String: ReferenceRangeReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeReview) {
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

        func list() -> [ReferenceRangeReview] {
            var out: [ReferenceRangeReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeReviewStore() -> any ReferenceRangeReviewStore {
        return MemoryReferenceRangeReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeReviewStore: ReferenceRangeReviewStore {
        var inner: MemoryReferenceRangeReviewStore
        var cache: TTLCache<ReferenceRangeReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeReviewStore, cache: TTLCache<ReferenceRangeReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeReview? {
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

        func save(_ item: ReferenceRangeReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeReview] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeReviewStore(_ inner: MemoryReferenceRangeReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeReviewStore {
        return CachedReferenceRangeReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range reviews. Empty fields match all.
    final class ReferenceRangeReviewQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeReview) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeReview]) -> [ReferenceRangeReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeReviews(_ store: any ReferenceRangeReviewStore, query: ReferenceRangeReviewQuery) -> [ReferenceRangeReview] {
        return query.apply(store.list())
    }
}
