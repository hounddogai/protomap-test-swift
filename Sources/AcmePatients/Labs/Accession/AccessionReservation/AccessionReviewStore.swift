import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession reviews by code.
    protocol AccessionReviewStore {
        func find(_ code: String) -> AccessionReview?
        func save(_ item: AccessionReview)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionReviewStore: AccessionReviewStore {
        var items: [String: AccessionReview]
        var order: [String]

        init(items: [String: AccessionReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionReview) {
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

        func list() -> [AccessionReview] {
            var out: [AccessionReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionReviewStore() -> any AccessionReviewStore {
        return MemoryAccessionReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionReviewStore: AccessionReviewStore {
        var inner: MemoryAccessionReviewStore
        var cache: TTLCache<AccessionReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionReviewStore, cache: TTLCache<AccessionReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionReview? {
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

        func save(_ item: AccessionReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionReview] {
            return inner.list()
        }
    }

    static func newCachedAccessionReviewStore(_ inner: MemoryAccessionReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionReviewStore {
        return CachedAccessionReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession reviews. Empty fields match all.
    final class AccessionReviewQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionReview) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [AccessionReview]) -> [AccessionReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionReviews(_ store: any AccessionReviewStore, query: AccessionReviewQuery) -> [AccessionReview] {
        return query.apply(store.list())
    }
}
