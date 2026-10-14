import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive isolation reviews by code.
    protocol AdaptiveIsolationReviewStore {
        func find(_ code: String) -> AdaptiveIsolationReview?
        func save(_ item: AdaptiveIsolationReview)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveIsolationReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveIsolationReviewStore: AdaptiveIsolationReviewStore {
        var items: [String: AdaptiveIsolationReview]
        var order: [String]

        init(items: [String: AdaptiveIsolationReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveIsolationReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveIsolationReview) {
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

        func list() -> [AdaptiveIsolationReview] {
            var out: [AdaptiveIsolationReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveIsolationReviewStore() -> any AdaptiveIsolationReviewStore {
        return MemoryAdaptiveIsolationReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveIsolationReviewStore: AdaptiveIsolationReviewStore {
        var inner: MemoryAdaptiveIsolationReviewStore
        var cache: TTLCache<AdaptiveIsolationReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveIsolationReviewStore, cache: TTLCache<AdaptiveIsolationReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveIsolationReview? {
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

        func save(_ item: AdaptiveIsolationReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveIsolationReview] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveIsolationReviewStore(_ inner: MemoryAdaptiveIsolationReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveIsolationReviewStore {
        return CachedAdaptiveIsolationReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive isolation reviews. Empty fields match all.
    final class AdaptiveIsolationReviewQuery {
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

        func matches(_ item: AdaptiveIsolationReview) -> Bool {
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

        func apply(_ items: [AdaptiveIsolationReview]) -> [AdaptiveIsolationReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveIsolationReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveIsolationReviews(_ store: any AdaptiveIsolationReviewStore, query: AdaptiveIsolationReviewQuery) -> [AdaptiveIsolationReview] {
        return query.apply(store.list())
    }
}
