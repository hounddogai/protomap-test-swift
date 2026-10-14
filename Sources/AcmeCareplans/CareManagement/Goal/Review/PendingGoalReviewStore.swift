import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps pending goal reviews by code.
    protocol PendingGoalReviewStore {
        func find(_ code: String) -> PendingGoalReview?
        func save(_ item: PendingGoalReview)
        func remove(_ code: String) -> Bool
        func list() -> [PendingGoalReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingGoalReviewStore: PendingGoalReviewStore {
        var items: [String: PendingGoalReview]
        var order: [String]

        init(items: [String: PendingGoalReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingGoalReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingGoalReview) {
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

        func list() -> [PendingGoalReview] {
            var out: [PendingGoalReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingGoalReviewStore() -> any PendingGoalReviewStore {
        return MemoryPendingGoalReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingGoalReviewStore: PendingGoalReviewStore {
        var inner: MemoryPendingGoalReviewStore
        var cache: TTLCache<PendingGoalReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingGoalReviewStore, cache: TTLCache<PendingGoalReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingGoalReview? {
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

        func save(_ item: PendingGoalReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingGoalReview] {
            return inner.list()
        }
    }

    static func newCachedPendingGoalReviewStore(_ inner: MemoryPendingGoalReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingGoalReviewStore {
        return CachedPendingGoalReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending goal reviews. Empty fields match all.
    final class PendingGoalReviewQuery {
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

        func matches(_ item: PendingGoalReview) -> Bool {
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

        func apply(_ items: [PendingGoalReview]) -> [PendingGoalReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingGoalReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingGoalReviews(_ store: any PendingGoalReviewStore, query: PendingGoalReviewQuery) -> [PendingGoalReview] {
        return query.apply(store.list())
    }
}
