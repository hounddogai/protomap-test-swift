import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual care protocol reviews by code.
    protocol ManualCareProtocolReviewStore {
        func find(_ code: String) -> ManualCareProtocolReview?
        func save(_ item: ManualCareProtocolReview)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCareProtocolReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCareProtocolReviewStore: ManualCareProtocolReviewStore {
        var items: [String: ManualCareProtocolReview]
        var order: [String]

        init(items: [String: ManualCareProtocolReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCareProtocolReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCareProtocolReview) {
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

        func list() -> [ManualCareProtocolReview] {
            var out: [ManualCareProtocolReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCareProtocolReviewStore() -> any ManualCareProtocolReviewStore {
        return MemoryManualCareProtocolReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCareProtocolReviewStore: ManualCareProtocolReviewStore {
        var inner: MemoryManualCareProtocolReviewStore
        var cache: TTLCache<ManualCareProtocolReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCareProtocolReviewStore, cache: TTLCache<ManualCareProtocolReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCareProtocolReview? {
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

        func save(_ item: ManualCareProtocolReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCareProtocolReview] {
            return inner.list()
        }
    }

    static func newCachedManualCareProtocolReviewStore(_ inner: MemoryManualCareProtocolReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCareProtocolReviewStore {
        return CachedManualCareProtocolReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual care protocol reviews. Empty fields match all.
    final class ManualCareProtocolReviewQuery {
        var region: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCareProtocolReview) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [ManualCareProtocolReview]) -> [ManualCareProtocolReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCareProtocolReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCareProtocolReviews(_ store: any ManualCareProtocolReviewStore, query: ManualCareProtocolReviewQuery) -> [ManualCareProtocolReview] {
        return query.apply(store.list())
    }
}
