import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered claim reviews by code.
    protocol TieredClaimReviewStore {
        func find(_ code: String) -> TieredClaimReview?
        func save(_ item: TieredClaimReview)
        func remove(_ code: String) -> Bool
        func list() -> [TieredClaimReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredClaimReviewStore: TieredClaimReviewStore {
        var items: [String: TieredClaimReview]
        var order: [String]

        init(items: [String: TieredClaimReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredClaimReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredClaimReview) {
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

        func list() -> [TieredClaimReview] {
            var out: [TieredClaimReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredClaimReviewStore() -> any TieredClaimReviewStore {
        return MemoryTieredClaimReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredClaimReviewStore: TieredClaimReviewStore {
        var inner: MemoryTieredClaimReviewStore
        var cache: TTLCache<TieredClaimReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredClaimReviewStore, cache: TTLCache<TieredClaimReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredClaimReview? {
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

        func save(_ item: TieredClaimReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredClaimReview] {
            return inner.list()
        }
    }

    static func newCachedTieredClaimReviewStore(_ inner: MemoryTieredClaimReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredClaimReviewStore {
        return CachedTieredClaimReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered claim reviews. Empty fields match all.
    final class TieredClaimReviewQuery {
        var unit: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredClaimReview) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredClaimReview]) -> [TieredClaimReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredClaimReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredClaimReviews(_ store: any TieredClaimReviewStore, query: TieredClaimReviewQuery) -> [TieredClaimReview] {
        return query.apply(store.list())
    }
}
