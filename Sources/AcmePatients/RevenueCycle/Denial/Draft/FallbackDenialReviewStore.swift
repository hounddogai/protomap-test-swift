import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback denial reviews by code.
    protocol FallbackDenialReviewStore {
        func find(_ code: String) -> FallbackDenialReview?
        func save(_ item: FallbackDenialReview)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDenialReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDenialReviewStore: FallbackDenialReviewStore {
        var items: [String: FallbackDenialReview]
        var order: [String]

        init(items: [String: FallbackDenialReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDenialReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDenialReview) {
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

        func list() -> [FallbackDenialReview] {
            var out: [FallbackDenialReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDenialReviewStore() -> any FallbackDenialReviewStore {
        return MemoryFallbackDenialReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDenialReviewStore: FallbackDenialReviewStore {
        var inner: MemoryFallbackDenialReviewStore
        var cache: TTLCache<FallbackDenialReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDenialReviewStore, cache: TTLCache<FallbackDenialReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDenialReview? {
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

        func save(_ item: FallbackDenialReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDenialReview] {
            return inner.list()
        }
    }

    static func newCachedFallbackDenialReviewStore(_ inner: MemoryFallbackDenialReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDenialReviewStore {
        return CachedFallbackDenialReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback denial reviews. Empty fields match all.
    final class FallbackDenialReviewQuery {
        var country: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDenialReview) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackDenialReview]) -> [FallbackDenialReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDenialReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDenialReviews(_ store: any FallbackDenialReviewStore, query: FallbackDenialReviewQuery) -> [FallbackDenialReview] {
        return query.apply(store.list())
    }
}
