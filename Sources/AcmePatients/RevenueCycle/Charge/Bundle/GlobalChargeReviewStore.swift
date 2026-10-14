import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps global charge reviews by code.
    protocol GlobalChargeReviewStore {
        func find(_ code: String) -> GlobalChargeReview?
        func save(_ item: GlobalChargeReview)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalChargeReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalChargeReviewStore: GlobalChargeReviewStore {
        var items: [String: GlobalChargeReview]
        var order: [String]

        init(items: [String: GlobalChargeReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalChargeReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalChargeReview) {
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

        func list() -> [GlobalChargeReview] {
            var out: [GlobalChargeReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalChargeReviewStore() -> any GlobalChargeReviewStore {
        return MemoryGlobalChargeReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalChargeReviewStore: GlobalChargeReviewStore {
        var inner: MemoryGlobalChargeReviewStore
        var cache: TTLCache<GlobalChargeReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalChargeReviewStore, cache: TTLCache<GlobalChargeReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalChargeReview? {
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

        func save(_ item: GlobalChargeReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalChargeReview] {
            return inner.list()
        }
    }

    static func newCachedGlobalChargeReviewStore(_ inner: MemoryGlobalChargeReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalChargeReviewStore {
        return CachedGlobalChargeReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global charge reviews. Empty fields match all.
    final class GlobalChargeReviewQuery {
        var segment: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalChargeReview) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [GlobalChargeReview]) -> [GlobalChargeReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalChargeReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalChargeReviews(_ store: any GlobalChargeReviewStore, query: GlobalChargeReviewQuery) -> [GlobalChargeReview] {
        return query.apply(store.list())
    }
}
