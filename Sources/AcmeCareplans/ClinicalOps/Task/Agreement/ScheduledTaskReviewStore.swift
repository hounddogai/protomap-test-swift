import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps scheduled task reviews by code.
    protocol ScheduledTaskReviewStore {
        func find(_ code: String) -> ScheduledTaskReview?
        func save(_ item: ScheduledTaskReview)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledTaskReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledTaskReviewStore: ScheduledTaskReviewStore {
        var items: [String: ScheduledTaskReview]
        var order: [String]

        init(items: [String: ScheduledTaskReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledTaskReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledTaskReview) {
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

        func list() -> [ScheduledTaskReview] {
            var out: [ScheduledTaskReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledTaskReviewStore() -> any ScheduledTaskReviewStore {
        return MemoryScheduledTaskReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledTaskReviewStore: ScheduledTaskReviewStore {
        var inner: MemoryScheduledTaskReviewStore
        var cache: TTLCache<ScheduledTaskReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledTaskReviewStore, cache: TTLCache<ScheduledTaskReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledTaskReview? {
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

        func save(_ item: ScheduledTaskReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledTaskReview] {
            return inner.list()
        }
    }

    static func newCachedScheduledTaskReviewStore(_ inner: MemoryScheduledTaskReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledTaskReviewStore {
        return CachedScheduledTaskReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled task reviews. Empty fields match all.
    final class ScheduledTaskReviewQuery {
        var label: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledTaskReview) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledTaskReview]) -> [ScheduledTaskReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledTaskReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledTaskReviews(_ store: any ScheduledTaskReviewStore, query: ScheduledTaskReviewQuery) -> [ScheduledTaskReview] {
        return query.apply(store.list())
    }
}
