import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps substitution reviews by code.
    protocol SubstitutionReviewStore {
        func find(_ code: String) -> SubstitutionReview?
        func save(_ item: SubstitutionReview)
        func remove(_ code: String) -> Bool
        func list() -> [SubstitutionReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySubstitutionReviewStore: SubstitutionReviewStore {
        var items: [String: SubstitutionReview]
        var order: [String]

        init(items: [String: SubstitutionReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SubstitutionReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SubstitutionReview) {
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

        func list() -> [SubstitutionReview] {
            var out: [SubstitutionReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySubstitutionReviewStore() -> any SubstitutionReviewStore {
        return MemorySubstitutionReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSubstitutionReviewStore: SubstitutionReviewStore {
        var inner: MemorySubstitutionReviewStore
        var cache: TTLCache<SubstitutionReview>
        var hits: Int
        var misses: Int

        init(inner: MemorySubstitutionReviewStore, cache: TTLCache<SubstitutionReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SubstitutionReview? {
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

        func save(_ item: SubstitutionReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SubstitutionReview] {
            return inner.list()
        }
    }

    static func newCachedSubstitutionReviewStore(_ inner: MemorySubstitutionReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SubstitutionReviewStore {
        return CachedSubstitutionReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects substitution reviews. Empty fields match all.
    final class SubstitutionReviewQuery {
        var title: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRatio: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SubstitutionReview) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SubstitutionReview]) -> [SubstitutionReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SubstitutionReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSubstitutionReviews(_ store: any SubstitutionReviewStore, query: SubstitutionReviewQuery) -> [SubstitutionReview] {
        return query.apply(store.list())
    }
}
