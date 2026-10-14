import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback closure reviews by code.
    protocol FallbackClosureReviewStore {
        func find(_ code: String) -> FallbackClosureReview?
        func save(_ item: FallbackClosureReview)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackClosureReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackClosureReviewStore: FallbackClosureReviewStore {
        var items: [String: FallbackClosureReview]
        var order: [String]

        init(items: [String: FallbackClosureReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackClosureReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackClosureReview) {
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

        func list() -> [FallbackClosureReview] {
            var out: [FallbackClosureReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackClosureReviewStore() -> any FallbackClosureReviewStore {
        return MemoryFallbackClosureReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackClosureReviewStore: FallbackClosureReviewStore {
        var inner: MemoryFallbackClosureReviewStore
        var cache: TTLCache<FallbackClosureReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackClosureReviewStore, cache: TTLCache<FallbackClosureReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackClosureReview? {
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

        func save(_ item: FallbackClosureReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackClosureReview] {
            return inner.list()
        }
    }

    static func newCachedFallbackClosureReviewStore(_ inner: MemoryFallbackClosureReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackClosureReviewStore {
        return CachedFallbackClosureReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback closure reviews. Empty fields match all.
    final class FallbackClosureReviewQuery {
        var unit: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minBudget: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackClosureReview) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [FallbackClosureReview]) -> [FallbackClosureReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackClosureReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackClosureReviews(_ store: any FallbackClosureReviewStore, query: FallbackClosureReviewQuery) -> [FallbackClosureReview] {
        return query.apply(store.list())
    }
}
