import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization estimates by code.
    protocol AuthorizationEstimateStore {
        func find(_ code: String) -> AuthorizationEstimate?
        func save(_ item: AuthorizationEstimate)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationEstimate]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationEstimateStore: AuthorizationEstimateStore {
        var items: [String: AuthorizationEstimate]
        var order: [String]

        init(items: [String: AuthorizationEstimate], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationEstimate? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationEstimate) {
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

        func list() -> [AuthorizationEstimate] {
            var out: [AuthorizationEstimate] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationEstimateStore() -> any AuthorizationEstimateStore {
        return MemoryAuthorizationEstimateStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationEstimateStore: AuthorizationEstimateStore {
        var inner: MemoryAuthorizationEstimateStore
        var cache: TTLCache<AuthorizationEstimate>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationEstimateStore, cache: TTLCache<AuthorizationEstimate>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationEstimate? {
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

        func save(_ item: AuthorizationEstimate) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationEstimate] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationEstimateStore(_ inner: MemoryAuthorizationEstimateStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationEstimateStore {
        return CachedAuthorizationEstimateStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization estimates. Empty fields match all.
    final class AuthorizationEstimateQuery {
        var category: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minRate: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationEstimate) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationEstimate]) -> [AuthorizationEstimate] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationEstimate) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationEstimates(_ store: any AuthorizationEstimateStore, query: AuthorizationEstimateQuery) -> [AuthorizationEstimate] {
        return query.apply(store.list())
    }
}
