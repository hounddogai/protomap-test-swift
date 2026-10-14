import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim reviews by code.
    protocol ClaimReviewStore {
        func find(_ code: String) -> ClaimReview?
        func save(_ item: ClaimReview)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimReviewStore: ClaimReviewStore {
        var items: [String: ClaimReview]
        var order: [String]

        init(items: [String: ClaimReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimReview) {
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

        func list() -> [ClaimReview] {
            var out: [ClaimReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimReviewStore() -> any ClaimReviewStore {
        return MemoryClaimReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimReviewStore: ClaimReviewStore {
        var inner: MemoryClaimReviewStore
        var cache: TTLCache<ClaimReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimReviewStore, cache: TTLCache<ClaimReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimReview? {
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

        func save(_ item: ClaimReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimReview] {
            return inner.list()
        }
    }

    static func newCachedClaimReviewStore(_ inner: MemoryClaimReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimReviewStore {
        return CachedClaimReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim reviews. Empty fields match all.
    final class ClaimReviewQuery {
        var name: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minBudget: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimReview]) -> [ClaimReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimReviews(_ store: any ClaimReviewStore, query: ClaimReviewQuery) -> [ClaimReview] {
        return query.apply(store.list())
    }
}
