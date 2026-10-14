import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps fallback formulary reviews by code.
    protocol FallbackFormularyReviewStore {
        func find(_ code: String) -> FallbackFormularyReview?
        func save(_ item: FallbackFormularyReview)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackFormularyReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackFormularyReviewStore: FallbackFormularyReviewStore {
        var items: [String: FallbackFormularyReview]
        var order: [String]

        init(items: [String: FallbackFormularyReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackFormularyReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackFormularyReview) {
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

        func list() -> [FallbackFormularyReview] {
            var out: [FallbackFormularyReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackFormularyReviewStore() -> any FallbackFormularyReviewStore {
        return MemoryFallbackFormularyReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackFormularyReviewStore: FallbackFormularyReviewStore {
        var inner: MemoryFallbackFormularyReviewStore
        var cache: TTLCache<FallbackFormularyReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackFormularyReviewStore, cache: TTLCache<FallbackFormularyReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackFormularyReview? {
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

        func save(_ item: FallbackFormularyReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackFormularyReview] {
            return inner.list()
        }
    }

    static func newCachedFallbackFormularyReviewStore(_ inner: MemoryFallbackFormularyReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackFormularyReviewStore {
        return CachedFallbackFormularyReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback formulary reviews. Empty fields match all.
    final class FallbackFormularyReviewQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackFormularyReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackFormularyReview]) -> [FallbackFormularyReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackFormularyReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackFormularyReviews(_ store: any FallbackFormularyReviewStore, query: FallbackFormularyReviewQuery) -> [FallbackFormularyReview] {
        return query.apply(store.list())
    }
}
