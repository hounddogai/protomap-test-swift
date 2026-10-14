import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps scheduled overtime reviews by code.
    protocol ScheduledOvertimeReviewStore {
        func find(_ code: String) -> ScheduledOvertimeReview?
        func save(_ item: ScheduledOvertimeReview)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledOvertimeReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledOvertimeReviewStore: ScheduledOvertimeReviewStore {
        var items: [String: ScheduledOvertimeReview]
        var order: [String]

        init(items: [String: ScheduledOvertimeReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledOvertimeReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledOvertimeReview) {
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

        func list() -> [ScheduledOvertimeReview] {
            var out: [ScheduledOvertimeReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledOvertimeReviewStore() -> any ScheduledOvertimeReviewStore {
        return MemoryScheduledOvertimeReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledOvertimeReviewStore: ScheduledOvertimeReviewStore {
        var inner: MemoryScheduledOvertimeReviewStore
        var cache: TTLCache<ScheduledOvertimeReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledOvertimeReviewStore, cache: TTLCache<ScheduledOvertimeReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledOvertimeReview? {
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

        func save(_ item: ScheduledOvertimeReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledOvertimeReview] {
            return inner.list()
        }
    }

    static func newCachedScheduledOvertimeReviewStore(_ inner: MemoryScheduledOvertimeReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledOvertimeReviewStore {
        return CachedScheduledOvertimeReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled overtime reviews. Empty fields match all.
    final class ScheduledOvertimeReviewQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledOvertimeReview) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledOvertimeReview]) -> [ScheduledOvertimeReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledOvertimeReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledOvertimeReviews(_ store: any ScheduledOvertimeReviewStore, query: ScheduledOvertimeReviewQuery) -> [ScheduledOvertimeReview] {
        return query.apply(store.list())
    }
}
