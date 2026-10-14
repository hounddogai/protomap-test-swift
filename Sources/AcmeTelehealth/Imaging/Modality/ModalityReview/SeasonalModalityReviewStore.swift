import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps seasonal modality reviews by code.
    protocol SeasonalModalityReviewStore {
        func find(_ code: String) -> SeasonalModalityReview?
        func save(_ item: SeasonalModalityReview)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalModalityReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalModalityReviewStore: SeasonalModalityReviewStore {
        var items: [String: SeasonalModalityReview]
        var order: [String]

        init(items: [String: SeasonalModalityReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalModalityReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalModalityReview) {
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

        func list() -> [SeasonalModalityReview] {
            var out: [SeasonalModalityReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalModalityReviewStore() -> any SeasonalModalityReviewStore {
        return MemorySeasonalModalityReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalModalityReviewStore: SeasonalModalityReviewStore {
        var inner: MemorySeasonalModalityReviewStore
        var cache: TTLCache<SeasonalModalityReview>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalModalityReviewStore, cache: TTLCache<SeasonalModalityReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalModalityReview? {
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

        func save(_ item: SeasonalModalityReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalModalityReview] {
            return inner.list()
        }
    }

    static func newCachedSeasonalModalityReviewStore(_ inner: MemorySeasonalModalityReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalModalityReviewStore {
        return CachedSeasonalModalityReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal modality reviews. Empty fields match all.
    final class SeasonalModalityReviewQuery {
        var name: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minWeight: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalModalityReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalModalityReview]) -> [SeasonalModalityReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalModalityReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalModalityReviews(_ store: any SeasonalModalityReviewStore, query: SeasonalModalityReviewQuery) -> [SeasonalModalityReview] {
        return query.apply(store.list())
    }
}
