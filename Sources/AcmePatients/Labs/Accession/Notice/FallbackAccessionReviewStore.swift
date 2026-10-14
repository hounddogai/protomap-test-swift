import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback accession reviews by code.
    protocol FallbackAccessionReviewStore {
        func find(_ code: String) -> FallbackAccessionReview?
        func save(_ item: FallbackAccessionReview)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackAccessionReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackAccessionReviewStore: FallbackAccessionReviewStore {
        var items: [String: FallbackAccessionReview]
        var order: [String]

        init(items: [String: FallbackAccessionReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackAccessionReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackAccessionReview) {
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

        func list() -> [FallbackAccessionReview] {
            var out: [FallbackAccessionReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackAccessionReviewStore() -> any FallbackAccessionReviewStore {
        return MemoryFallbackAccessionReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackAccessionReviewStore: FallbackAccessionReviewStore {
        var inner: MemoryFallbackAccessionReviewStore
        var cache: TTLCache<FallbackAccessionReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackAccessionReviewStore, cache: TTLCache<FallbackAccessionReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackAccessionReview? {
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

        func save(_ item: FallbackAccessionReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackAccessionReview] {
            return inner.list()
        }
    }

    static func newCachedFallbackAccessionReviewStore(_ inner: MemoryFallbackAccessionReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackAccessionReviewStore {
        return CachedFallbackAccessionReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback accession reviews. Empty fields match all.
    final class FallbackAccessionReviewQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackAccessionReview) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackAccessionReview]) -> [FallbackAccessionReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackAccessionReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackAccessionReviews(_ store: any FallbackAccessionReviewStore, query: FallbackAccessionReviewQuery) -> [FallbackAccessionReview] {
        return query.apply(store.list())
    }
}
