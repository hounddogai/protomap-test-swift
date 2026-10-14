import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization variances by code.
    protocol AuthorizationVarianceStore {
        func find(_ code: String) -> AuthorizationVariance?
        func save(_ item: AuthorizationVariance)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationVarianceStore: AuthorizationVarianceStore {
        var items: [String: AuthorizationVariance]
        var order: [String]

        init(items: [String: AuthorizationVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationVariance) {
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

        func list() -> [AuthorizationVariance] {
            var out: [AuthorizationVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationVarianceStore() -> any AuthorizationVarianceStore {
        return MemoryAuthorizationVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationVarianceStore: AuthorizationVarianceStore {
        var inner: MemoryAuthorizationVarianceStore
        var cache: TTLCache<AuthorizationVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationVarianceStore, cache: TTLCache<AuthorizationVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationVariance? {
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

        func save(_ item: AuthorizationVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationVariance] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationVarianceStore(_ inner: MemoryAuthorizationVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationVarianceStore {
        return CachedAuthorizationVarianceStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization variances. Empty fields match all.
    final class AuthorizationVarianceQuery {
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

        func matches(_ item: AuthorizationVariance) -> Bool {
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

        func apply(_ items: [AuthorizationVariance]) -> [AuthorizationVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationVariances(_ store: any AuthorizationVarianceStore, query: AuthorizationVarianceQuery) -> [AuthorizationVariance] {
        return query.apply(store.list())
    }
}
