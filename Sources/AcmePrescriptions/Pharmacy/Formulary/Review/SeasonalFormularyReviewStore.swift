import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps seasonal formulary reviews by code.
    protocol SeasonalFormularyReviewStore {
        func find(_ code: String) -> SeasonalFormularyReview?
        func save(_ item: SeasonalFormularyReview)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalFormularyReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalFormularyReviewStore: SeasonalFormularyReviewStore {
        var items: [String: SeasonalFormularyReview]
        var order: [String]

        init(items: [String: SeasonalFormularyReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalFormularyReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalFormularyReview) {
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

        func list() -> [SeasonalFormularyReview] {
            var out: [SeasonalFormularyReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalFormularyReviewStore() -> any SeasonalFormularyReviewStore {
        return MemorySeasonalFormularyReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalFormularyReviewStore: SeasonalFormularyReviewStore {
        var inner: MemorySeasonalFormularyReviewStore
        var cache: TTLCache<SeasonalFormularyReview>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalFormularyReviewStore, cache: TTLCache<SeasonalFormularyReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalFormularyReview? {
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

        func save(_ item: SeasonalFormularyReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalFormularyReview] {
            return inner.list()
        }
    }

    static func newCachedSeasonalFormularyReviewStore(_ inner: MemorySeasonalFormularyReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalFormularyReviewStore {
        return CachedSeasonalFormularyReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal formulary reviews. Empty fields match all.
    final class SeasonalFormularyReviewQuery {
        var title: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minBudget: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalFormularyReview) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [SeasonalFormularyReview]) -> [SeasonalFormularyReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalFormularyReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalFormularyReviews(_ store: any SeasonalFormularyReviewStore, query: SeasonalFormularyReviewQuery) -> [SeasonalFormularyReview] {
        return query.apply(store.list())
    }
}
