import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory reviews by code.
    protocol InventoryReviewStore {
        func find(_ code: String) -> InventoryReview?
        func save(_ item: InventoryReview)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryReviewStore: InventoryReviewStore {
        var items: [String: InventoryReview]
        var order: [String]

        init(items: [String: InventoryReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryReview) {
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

        func list() -> [InventoryReview] {
            var out: [InventoryReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryReviewStore() -> any InventoryReviewStore {
        return MemoryInventoryReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryReviewStore: InventoryReviewStore {
        var inner: MemoryInventoryReviewStore
        var cache: TTLCache<InventoryReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryReviewStore, cache: TTLCache<InventoryReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryReview? {
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

        func save(_ item: InventoryReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryReview] {
            return inner.list()
        }
    }

    static func newCachedInventoryReviewStore(_ inner: MemoryInventoryReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryReviewStore {
        return CachedInventoryReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory reviews. Empty fields match all.
    final class InventoryReviewQuery {
        var channel: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryReview) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryReview]) -> [InventoryReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryReviews(_ store: any InventoryReviewStore, query: InventoryReviewQuery) -> [InventoryReview] {
        return query.apply(store.list())
    }
}
