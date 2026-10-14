import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set reviews by code.
    protocol OrderSetReviewStore {
        func find(_ code: String) -> OrderSetReview?
        func save(_ item: OrderSetReview)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetReviewStore: OrderSetReviewStore {
        var items: [String: OrderSetReview]
        var order: [String]

        init(items: [String: OrderSetReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetReview) {
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

        func list() -> [OrderSetReview] {
            var out: [OrderSetReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetReviewStore() -> any OrderSetReviewStore {
        return MemoryOrderSetReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetReviewStore: OrderSetReviewStore {
        var inner: MemoryOrderSetReviewStore
        var cache: TTLCache<OrderSetReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetReviewStore, cache: TTLCache<OrderSetReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetReview? {
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

        func save(_ item: OrderSetReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetReview] {
            return inner.list()
        }
    }

    static func newCachedOrderSetReviewStore(_ inner: MemoryOrderSetReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetReviewStore {
        return CachedOrderSetReviewStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set reviews. Empty fields match all.
    final class OrderSetReviewQuery {
        var label: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCopay: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetReview) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetReview]) -> [OrderSetReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetReviews(_ store: any OrderSetReviewStore, query: OrderSetReviewQuery) -> [OrderSetReview] {
        return query.apply(store.list())
    }
}
