import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps capped dispense reviews by code.
    protocol CappedDispenseReviewStore {
        func find(_ code: String) -> CappedDispenseReview?
        func save(_ item: CappedDispenseReview)
        func remove(_ code: String) -> Bool
        func list() -> [CappedDispenseReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedDispenseReviewStore: CappedDispenseReviewStore {
        var items: [String: CappedDispenseReview]
        var order: [String]

        init(items: [String: CappedDispenseReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedDispenseReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedDispenseReview) {
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

        func list() -> [CappedDispenseReview] {
            var out: [CappedDispenseReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedDispenseReviewStore() -> any CappedDispenseReviewStore {
        return MemoryCappedDispenseReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedDispenseReviewStore: CappedDispenseReviewStore {
        var inner: MemoryCappedDispenseReviewStore
        var cache: TTLCache<CappedDispenseReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedDispenseReviewStore, cache: TTLCache<CappedDispenseReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedDispenseReview? {
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

        func save(_ item: CappedDispenseReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedDispenseReview] {
            return inner.list()
        }
    }

    static func newCachedCappedDispenseReviewStore(_ inner: MemoryCappedDispenseReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedDispenseReviewStore {
        return CachedCappedDispenseReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped dispense reviews. Empty fields match all.
    final class CappedDispenseReviewQuery {
        var channel: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minPriority: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedDispenseReview) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedDispenseReview]) -> [CappedDispenseReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedDispenseReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedDispenseReviews(_ store: any CappedDispenseReviewStore, query: CappedDispenseReviewQuery) -> [CappedDispenseReview] {
        return query.apply(store.list())
    }
}
