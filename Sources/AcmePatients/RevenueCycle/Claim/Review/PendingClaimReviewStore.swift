import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending claim reviews by code.
    protocol PendingClaimReviewStore {
        func find(_ code: String) -> PendingClaimReview?
        func save(_ item: PendingClaimReview)
        func remove(_ code: String) -> Bool
        func list() -> [PendingClaimReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingClaimReviewStore: PendingClaimReviewStore {
        var items: [String: PendingClaimReview]
        var order: [String]

        init(items: [String: PendingClaimReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingClaimReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingClaimReview) {
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

        func list() -> [PendingClaimReview] {
            var out: [PendingClaimReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingClaimReviewStore() -> any PendingClaimReviewStore {
        return MemoryPendingClaimReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingClaimReviewStore: PendingClaimReviewStore {
        var inner: MemoryPendingClaimReviewStore
        var cache: TTLCache<PendingClaimReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingClaimReviewStore, cache: TTLCache<PendingClaimReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingClaimReview? {
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

        func save(_ item: PendingClaimReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingClaimReview] {
            return inner.list()
        }
    }

    static func newCachedPendingClaimReviewStore(_ inner: MemoryPendingClaimReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingClaimReviewStore {
        return CachedPendingClaimReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending claim reviews. Empty fields match all.
    final class PendingClaimReviewQuery {
        var category: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingClaimReview) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingClaimReview]) -> [PendingClaimReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingClaimReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingClaimReviews(_ store: any PendingClaimReviewStore, query: PendingClaimReviewQuery) -> [PendingClaimReview] {
        return query.apply(store.list())
    }
}
