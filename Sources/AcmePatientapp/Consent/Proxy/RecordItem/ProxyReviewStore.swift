import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy reviews by code.
    protocol ProxyReviewStore {
        func find(_ code: String) -> ProxyReview?
        func save(_ item: ProxyReview)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyReviewStore: ProxyReviewStore {
        var items: [String: ProxyReview]
        var order: [String]

        init(items: [String: ProxyReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyReview) {
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

        func list() -> [ProxyReview] {
            var out: [ProxyReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyReviewStore() -> any ProxyReviewStore {
        return MemoryProxyReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyReviewStore: ProxyReviewStore {
        var inner: MemoryProxyReviewStore
        var cache: TTLCache<ProxyReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyReviewStore, cache: TTLCache<ProxyReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyReview? {
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

        func save(_ item: ProxyReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyReview] {
            return inner.list()
        }
    }

    static func newCachedProxyReviewStore(_ inner: MemoryProxyReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyReviewStore {
        return CachedProxyReviewStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy reviews. Empty fields match all.
    final class ProxyReviewQuery {
        var ward: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRetries: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyReview) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [ProxyReview]) -> [ProxyReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyReviews(_ store: any ProxyReviewStore, query: ProxyReviewQuery) -> [ProxyReview] {
        return query.apply(store.list())
    }
}
