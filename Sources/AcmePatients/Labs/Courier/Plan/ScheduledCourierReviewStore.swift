import AcmePlatform
import Foundation

extension Labs {
    /// Keeps scheduled courier reviews by code.
    protocol ScheduledCourierReviewStore {
        func find(_ code: String) -> ScheduledCourierReview?
        func save(_ item: ScheduledCourierReview)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCourierReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCourierReviewStore: ScheduledCourierReviewStore {
        var items: [String: ScheduledCourierReview]
        var order: [String]

        init(items: [String: ScheduledCourierReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCourierReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCourierReview) {
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

        func list() -> [ScheduledCourierReview] {
            var out: [ScheduledCourierReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCourierReviewStore() -> any ScheduledCourierReviewStore {
        return MemoryScheduledCourierReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCourierReviewStore: ScheduledCourierReviewStore {
        var inner: MemoryScheduledCourierReviewStore
        var cache: TTLCache<ScheduledCourierReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCourierReviewStore, cache: TTLCache<ScheduledCourierReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCourierReview? {
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

        func save(_ item: ScheduledCourierReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCourierReview] {
            return inner.list()
        }
    }

    static func newCachedScheduledCourierReviewStore(_ inner: MemoryScheduledCourierReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCourierReviewStore {
        return CachedScheduledCourierReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled courier reviews. Empty fields match all.
    final class ScheduledCourierReviewQuery {
        var name: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCourierReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledCourierReview]) -> [ScheduledCourierReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCourierReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCourierReviews(_ store: any ScheduledCourierReviewStore, query: ScheduledCourierReviewQuery) -> [ScheduledCourierReview] {
        return query.apply(store.list())
    }
}
