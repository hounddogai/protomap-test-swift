import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps fallback dispense reviews by code.
    protocol FallbackDispenseReviewStore {
        func find(_ code: String) -> FallbackDispenseReview?
        func save(_ item: FallbackDispenseReview)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDispenseReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDispenseReviewStore: FallbackDispenseReviewStore {
        var items: [String: FallbackDispenseReview]
        var order: [String]

        init(items: [String: FallbackDispenseReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDispenseReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDispenseReview) {
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

        func list() -> [FallbackDispenseReview] {
            var out: [FallbackDispenseReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDispenseReviewStore() -> any FallbackDispenseReviewStore {
        return MemoryFallbackDispenseReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDispenseReviewStore: FallbackDispenseReviewStore {
        var inner: MemoryFallbackDispenseReviewStore
        var cache: TTLCache<FallbackDispenseReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDispenseReviewStore, cache: TTLCache<FallbackDispenseReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDispenseReview? {
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

        func save(_ item: FallbackDispenseReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDispenseReview] {
            return inner.list()
        }
    }

    static func newCachedFallbackDispenseReviewStore(_ inner: MemoryFallbackDispenseReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDispenseReviewStore {
        return CachedFallbackDispenseReviewStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback dispense reviews. Empty fields match all.
    final class FallbackDispenseReviewQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDispenseReview) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackDispenseReview]) -> [FallbackDispenseReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDispenseReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDispenseReviews(_ store: any FallbackDispenseReviewStore, query: FallbackDispenseReviewQuery) -> [FallbackDispenseReview] {
        return query.apply(store.list())
    }
}
