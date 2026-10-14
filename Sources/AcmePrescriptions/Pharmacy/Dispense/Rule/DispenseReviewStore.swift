import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense reviews by code.
    protocol DispenseReviewStore {
        func find(_ code: String) -> DispenseReview?
        func save(_ item: DispenseReview)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseReviewStore: DispenseReviewStore {
        var items: [String: DispenseReview]
        var order: [String]

        init(items: [String: DispenseReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseReview) {
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

        func list() -> [DispenseReview] {
            var out: [DispenseReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseReviewStore() -> any DispenseReviewStore {
        return MemoryDispenseReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseReviewStore: DispenseReviewStore {
        var inner: MemoryDispenseReviewStore
        var cache: TTLCache<DispenseReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseReviewStore, cache: TTLCache<DispenseReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseReview? {
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

        func save(_ item: DispenseReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseReview] {
            return inner.list()
        }
    }

    static func newCachedDispenseReviewStore(_ inner: MemoryDispenseReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseReviewStore {
        return CachedDispenseReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense reviews. Empty fields match all.
    final class DispenseReviewQuery {
        var channel: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRetries: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseReview) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseReview]) -> [DispenseReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseReviews(_ store: any DispenseReviewStore, query: DispenseReviewQuery) -> [DispenseReview] {
        return query.apply(store.list())
    }
}
