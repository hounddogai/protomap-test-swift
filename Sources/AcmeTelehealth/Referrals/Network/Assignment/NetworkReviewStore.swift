import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network reviews by code.
    protocol NetworkReviewStore {
        func find(_ code: String) -> NetworkReview?
        func save(_ item: NetworkReview)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkReview]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkReviewStore: NetworkReviewStore {
        var items: [String: NetworkReview]
        var order: [String]

        init(items: [String: NetworkReview], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkReview? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkReview) {
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

        func list() -> [NetworkReview] {
            var out: [NetworkReview] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkReviewStore() -> any NetworkReviewStore {
        return MemoryNetworkReviewStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkReviewStore: NetworkReviewStore {
        var inner: MemoryNetworkReviewStore
        var cache: TTLCache<NetworkReview>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkReviewStore, cache: TTLCache<NetworkReview>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkReview? {
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

        func save(_ item: NetworkReview) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkReview] {
            return inner.list()
        }
    }

    static func newCachedNetworkReviewStore(_ inner: MemoryNetworkReviewStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkReviewStore {
        return CachedNetworkReviewStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network reviews. Empty fields match all.
    final class NetworkReviewQuery {
        var name: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkReview) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkReview]) -> [NetworkReview] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkReview) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkReviews(_ store: any NetworkReviewStore, query: NetworkReviewQuery) -> [NetworkReview] {
        return query.apply(store.list())
    }
}
