import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge reviews by code.
    protocol ChargeReviewStore {
        func find(_ code: String) -> ChargeReview?
        func save(_ item: ChargeReview)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeReviewStore: ChargeReviewStore {
        var items: [String: ChargeReview]
        var order: [String]

        init(items: [String: ChargeReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeReview) {
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

        func list() -> [ChargeReview] {
            var out: [ChargeReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeReviewStore() -> any ChargeReviewStore {
        return MemoryChargeReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeReviewStore: ChargeReviewStore {
        var inner: MemoryChargeReviewStore
        var cache: TTLCache<ChargeReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeReviewStore, cache: TTLCache<ChargeReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeReview? {
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

        func save(_ item: ChargeReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeReview] {
            return inner.list()
        }
    }

    static func newCachedChargeReviewStore(_ inner: MemoryChargeReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeReviewStore {
        return CachedChargeReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge reviews. Empty fields match all.
    final class ChargeReviewQuery {
        var segment: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeReview) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeReview]) -> [ChargeReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeReviews(_ store: any ChargeReviewStore, query: ChargeReviewQuery) -> [ChargeReview] {
        return query.apply(store.list())
    }
}
