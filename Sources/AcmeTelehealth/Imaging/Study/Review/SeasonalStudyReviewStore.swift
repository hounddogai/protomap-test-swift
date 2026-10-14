import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal study reviews by code.
    protocol SeasonalStudyReviewStore {
        func find(_ code: String) -> SeasonalStudyReview?
        func save(_ item: SeasonalStudyReview)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalStudyReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalStudyReviewStore: SeasonalStudyReviewStore {
        var items: [String: SeasonalStudyReview]
        var order: [String]

        init(items: [String: SeasonalStudyReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalStudyReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalStudyReview) {
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

        func list() -> [SeasonalStudyReview] {
            var out: [SeasonalStudyReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalStudyReviewStore() -> any SeasonalStudyReviewStore {
        return MemorySeasonalStudyReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalStudyReviewStore: SeasonalStudyReviewStore {
        var inner: MemorySeasonalStudyReviewStore
        var cache: TTLCache<SeasonalStudyReview>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalStudyReviewStore, cache: TTLCache<SeasonalStudyReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalStudyReview? {
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

        func save(_ item: SeasonalStudyReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalStudyReview] {
            return inner.list()
        }
    }

    static func newCachedSeasonalStudyReviewStore(_ inner: MemorySeasonalStudyReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalStudyReviewStore {
        return CachedSeasonalStudyReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal study reviews. Empty fields match all.
    final class SeasonalStudyReviewQuery {
        var segment: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalStudyReview) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalStudyReview]) -> [SeasonalStudyReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalStudyReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalStudyReviews(_ store: any SeasonalStudyReviewStore, query: SeasonalStudyReviewQuery) -> [SeasonalStudyReview] {
        return query.apply(store.list())
    }
}
