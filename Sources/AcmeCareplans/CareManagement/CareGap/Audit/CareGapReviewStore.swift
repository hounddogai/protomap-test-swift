import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap reviews by code.
    protocol CareGapReviewStore {
        func find(_ code: String) -> CareGapReview?
        func save(_ item: CareGapReview)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapReviewStore: CareGapReviewStore {
        var items: [String: CareGapReview]
        var order: [String]

        init(items: [String: CareGapReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapReview) {
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

        func list() -> [CareGapReview] {
            var out: [CareGapReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapReviewStore() -> any CareGapReviewStore {
        return MemoryCareGapReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapReviewStore: CareGapReviewStore {
        var inner: MemoryCareGapReviewStore
        var cache: TTLCache<CareGapReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapReviewStore, cache: TTLCache<CareGapReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapReview? {
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

        func save(_ item: CareGapReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapReview] {
            return inner.list()
        }
    }

    static func newCachedCareGapReviewStore(_ inner: MemoryCareGapReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapReviewStore {
        return CachedCareGapReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap reviews. Empty fields match all.
    final class CareGapReviewQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapReview) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapReview]) -> [CareGapReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapReviews(_ store: any CareGapReviewStore, query: CareGapReviewQuery) -> [CareGapReview] {
        return query.apply(store.list())
    }
}
