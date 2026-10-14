import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier reviews by code.
    protocol CourierReviewStore {
        func find(_ code: String) -> CourierReview?
        func save(_ item: CourierReview)
        func remove(_ code: String) -> Bool
        func list() -> [CourierReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierReviewStore: CourierReviewStore {
        var items: [String: CourierReview]
        var order: [String]

        init(items: [String: CourierReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierReview) {
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

        func list() -> [CourierReview] {
            var out: [CourierReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierReviewStore() -> any CourierReviewStore {
        return MemoryCourierReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierReviewStore: CourierReviewStore {
        var inner: MemoryCourierReviewStore
        var cache: TTLCache<CourierReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierReviewStore, cache: TTLCache<CourierReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierReview? {
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

        func save(_ item: CourierReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierReview] {
            return inner.list()
        }
    }

    static func newCachedCourierReviewStore(_ inner: MemoryCourierReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierReviewStore {
        return CachedCourierReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier reviews. Empty fields match all.
    final class CourierReviewQuery {
        var unit: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierReview) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierReview]) -> [CourierReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierReviews(_ store: any CourierReviewStore, query: CourierReviewQuery) -> [CourierReview] {
        return query.apply(store.list())
    }
}
