import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled language reviews by code.
    protocol ScheduledLanguageReviewStore {
        func find(_ code: String) -> ScheduledLanguageReview?
        func save(_ item: ScheduledLanguageReview)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledLanguageReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledLanguageReviewStore: ScheduledLanguageReviewStore {
        var items: [String: ScheduledLanguageReview]
        var order: [String]

        init(items: [String: ScheduledLanguageReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledLanguageReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledLanguageReview) {
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

        func list() -> [ScheduledLanguageReview] {
            var out: [ScheduledLanguageReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledLanguageReviewStore() -> any ScheduledLanguageReviewStore {
        return MemoryScheduledLanguageReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledLanguageReviewStore: ScheduledLanguageReviewStore {
        var inner: MemoryScheduledLanguageReviewStore
        var cache: TTLCache<ScheduledLanguageReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledLanguageReviewStore, cache: TTLCache<ScheduledLanguageReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledLanguageReview? {
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

        func save(_ item: ScheduledLanguageReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledLanguageReview] {
            return inner.list()
        }
    }

    static func newCachedScheduledLanguageReviewStore(_ inner: MemoryScheduledLanguageReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledLanguageReviewStore {
        return CachedScheduledLanguageReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled language reviews. Empty fields match all.
    final class ScheduledLanguageReviewQuery {
        var category: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledLanguageReview) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledLanguageReview]) -> [ScheduledLanguageReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledLanguageReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledLanguageReviews(_ store: any ScheduledLanguageReviewStore, query: ScheduledLanguageReviewQuery) -> [ScheduledLanguageReview] {
        return query.apply(store.list())
    }
}
