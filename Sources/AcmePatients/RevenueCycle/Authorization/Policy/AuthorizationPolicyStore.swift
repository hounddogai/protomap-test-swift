import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization policies by code.
    protocol AuthorizationPolicyStore {
        func find(_ code: String) -> AuthorizationPolicy?
        func save(_ item: AuthorizationPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationPolicyStore: AuthorizationPolicyStore {
        var items: [String: AuthorizationPolicy]
        var order: [String]

        init(items: [String: AuthorizationPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationPolicy) {
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

        func list() -> [AuthorizationPolicy] {
            var out: [AuthorizationPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationPolicyStore() -> any AuthorizationPolicyStore {
        return MemoryAuthorizationPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationPolicyStore: AuthorizationPolicyStore {
        var inner: MemoryAuthorizationPolicyStore
        var cache: TTLCache<AuthorizationPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationPolicyStore, cache: TTLCache<AuthorizationPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationPolicy? {
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

        func save(_ item: AuthorizationPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationPolicy] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationPolicyStore(_ inner: MemoryAuthorizationPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationPolicyStore {
        return CachedAuthorizationPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization policies. Empty fields match all.
    final class AuthorizationPolicyQuery {
        var unit: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationPolicy) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationPolicy]) -> [AuthorizationPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationPolicies(_ store: any AuthorizationPolicyStore, query: AuthorizationPolicyQuery) -> [AuthorizationPolicy] {
        return query.apply(store.list())
    }
}
