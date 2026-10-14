import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default courier reviews by code.
    protocol DefaultCourierReviewStore {
        func find(_ code: String) -> DefaultCourierReview?
        func save(_ item: DefaultCourierReview)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCourierReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCourierReviewStore: DefaultCourierReviewStore {
        var items: [String: DefaultCourierReview]
        var order: [String]

        init(items: [String: DefaultCourierReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCourierReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCourierReview) {
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

        func list() -> [DefaultCourierReview] {
            var out: [DefaultCourierReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCourierReviewStore() -> any DefaultCourierReviewStore {
        return MemoryDefaultCourierReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCourierReviewStore: DefaultCourierReviewStore {
        var inner: MemoryDefaultCourierReviewStore
        var cache: TTLCache<DefaultCourierReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCourierReviewStore, cache: TTLCache<DefaultCourierReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCourierReview? {
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

        func save(_ item: DefaultCourierReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCourierReview] {
            return inner.list()
        }
    }

    static func newCachedDefaultCourierReviewStore(_ inner: MemoryDefaultCourierReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCourierReviewStore {
        return CachedDefaultCourierReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default courier reviews. Empty fields match all.
    final class DefaultCourierReviewQuery {
        var region: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCourierReview) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCourierReview]) -> [DefaultCourierReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCourierReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCourierReviews(_ store: any DefaultCourierReviewStore, query: DefaultCourierReviewQuery) -> [DefaultCourierReview] {
        return query.apply(store.list())
    }
}
