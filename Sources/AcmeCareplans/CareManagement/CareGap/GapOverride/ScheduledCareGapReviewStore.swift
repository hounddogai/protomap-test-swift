import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps scheduled care gap reviews by code.
    protocol ScheduledCareGapReviewStore {
        func find(_ code: String) -> ScheduledCareGapReview?
        func save(_ item: ScheduledCareGapReview)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCareGapReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCareGapReviewStore: ScheduledCareGapReviewStore {
        var items: [String: ScheduledCareGapReview]
        var order: [String]

        init(items: [String: ScheduledCareGapReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCareGapReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCareGapReview) {
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

        func list() -> [ScheduledCareGapReview] {
            var out: [ScheduledCareGapReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCareGapReviewStore() -> any ScheduledCareGapReviewStore {
        return MemoryScheduledCareGapReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCareGapReviewStore: ScheduledCareGapReviewStore {
        var inner: MemoryScheduledCareGapReviewStore
        var cache: TTLCache<ScheduledCareGapReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCareGapReviewStore, cache: TTLCache<ScheduledCareGapReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCareGapReview? {
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

        func save(_ item: ScheduledCareGapReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCareGapReview] {
            return inner.list()
        }
    }

    static func newCachedScheduledCareGapReviewStore(_ inner: MemoryScheduledCareGapReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCareGapReviewStore {
        return CachedScheduledCareGapReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled care gap reviews. Empty fields match all.
    final class ScheduledCareGapReviewQuery {
        var region: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minAmount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCareGapReview) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledCareGapReview]) -> [ScheduledCareGapReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCareGapReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCareGapReviews(_ store: any ScheduledCareGapReviewStore, query: ScheduledCareGapReviewQuery) -> [ScheduledCareGapReview] {
        return query.apply(store.list())
    }
}
