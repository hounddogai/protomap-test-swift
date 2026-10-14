import AcmePlatform
import Foundation

extension Consent {
    /// Keeps lenient proxy reviews by code.
    protocol LenientProxyReviewStore {
        func find(_ code: String) -> LenientProxyReview?
        func save(_ item: LenientProxyReview)
        func remove(_ code: String) -> Bool
        func list() -> [LenientProxyReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientProxyReviewStore: LenientProxyReviewStore {
        var items: [String: LenientProxyReview]
        var order: [String]

        init(items: [String: LenientProxyReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientProxyReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientProxyReview) {
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

        func list() -> [LenientProxyReview] {
            var out: [LenientProxyReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientProxyReviewStore() -> any LenientProxyReviewStore {
        return MemoryLenientProxyReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientProxyReviewStore: LenientProxyReviewStore {
        var inner: MemoryLenientProxyReviewStore
        var cache: TTLCache<LenientProxyReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientProxyReviewStore, cache: TTLCache<LenientProxyReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientProxyReview? {
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

        func save(_ item: LenientProxyReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientProxyReview] {
            return inner.list()
        }
    }

    static func newCachedLenientProxyReviewStore(_ inner: MemoryLenientProxyReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientProxyReviewStore {
        return CachedLenientProxyReviewStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient proxy reviews. Empty fields match all.
    final class LenientProxyReviewQuery {
        var source: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minWeight: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientProxyReview) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientProxyReview]) -> [LenientProxyReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientProxyReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientProxyReviews(_ store: any LenientProxyReviewStore, query: LenientProxyReviewQuery) -> [LenientProxyReview] {
        return query.apply(store.list())
    }
}
