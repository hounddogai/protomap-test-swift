import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction reviews by code.
    protocol InteractionReviewStore {
        func find(_ code: String) -> InteractionReview?
        func save(_ item: InteractionReview)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionReviewStore: InteractionReviewStore {
        var items: [String: InteractionReview]
        var order: [String]

        init(items: [String: InteractionReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionReview) {
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

        func list() -> [InteractionReview] {
            var out: [InteractionReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionReviewStore() -> any InteractionReviewStore {
        return MemoryInteractionReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionReviewStore: InteractionReviewStore {
        var inner: MemoryInteractionReviewStore
        var cache: TTLCache<InteractionReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionReviewStore, cache: TTLCache<InteractionReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionReview? {
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

        func save(_ item: InteractionReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionReview] {
            return inner.list()
        }
    }

    static func newCachedInteractionReviewStore(_ inner: MemoryInteractionReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionReviewStore {
        return CachedInteractionReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction reviews. Empty fields match all.
    final class InteractionReviewQuery {
        var label: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRetries: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionReview) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [InteractionReview]) -> [InteractionReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionReviews(_ store: any InteractionReviewStore, query: InteractionReviewQuery) -> [InteractionReview] {
        return query.apply(store.list())
    }
}
