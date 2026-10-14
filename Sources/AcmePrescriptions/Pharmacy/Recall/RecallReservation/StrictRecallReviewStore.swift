import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps strict recall reviews by code.
    protocol StrictRecallReviewStore {
        func find(_ code: String) -> StrictRecallReview?
        func save(_ item: StrictRecallReview)
        func remove(_ code: String) -> Bool
        func list() -> [StrictRecallReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictRecallReviewStore: StrictRecallReviewStore {
        var items: [String: StrictRecallReview]
        var order: [String]

        init(items: [String: StrictRecallReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictRecallReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictRecallReview) {
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

        func list() -> [StrictRecallReview] {
            var out: [StrictRecallReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictRecallReviewStore() -> any StrictRecallReviewStore {
        return MemoryStrictRecallReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictRecallReviewStore: StrictRecallReviewStore {
        var inner: MemoryStrictRecallReviewStore
        var cache: TTLCache<StrictRecallReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictRecallReviewStore, cache: TTLCache<StrictRecallReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictRecallReview? {
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

        func save(_ item: StrictRecallReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictRecallReview] {
            return inner.list()
        }
    }

    static func newCachedStrictRecallReviewStore(_ inner: MemoryStrictRecallReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictRecallReviewStore {
        return CachedStrictRecallReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict recall reviews. Empty fields match all.
    final class StrictRecallReviewQuery {
        var country: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictRecallReview) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictRecallReview]) -> [StrictRecallReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictRecallReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictRecallReviews(_ store: any StrictRecallReviewStore, query: StrictRecallReviewQuery) -> [StrictRecallReview] {
        return query.apply(store.list())
    }
}
