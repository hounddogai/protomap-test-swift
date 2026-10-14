import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization overrides by code.
    protocol AuthorizationOverrideStore {
        func find(_ code: String) -> AuthorizationOverride?
        func save(_ item: AuthorizationOverride)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationOverrideStore: AuthorizationOverrideStore {
        var items: [String: AuthorizationOverride]
        var order: [String]

        init(items: [String: AuthorizationOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationOverride) {
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

        func list() -> [AuthorizationOverride] {
            var out: [AuthorizationOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationOverrideStore() -> any AuthorizationOverrideStore {
        return MemoryAuthorizationOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationOverrideStore: AuthorizationOverrideStore {
        var inner: MemoryAuthorizationOverrideStore
        var cache: TTLCache<AuthorizationOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationOverrideStore, cache: TTLCache<AuthorizationOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationOverride? {
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

        func save(_ item: AuthorizationOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationOverride] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationOverrideStore(_ inner: MemoryAuthorizationOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationOverrideStore {
        return CachedAuthorizationOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization overrides. Empty fields match all.
    final class AuthorizationOverrideQuery {
        var title: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minBudget: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationOverride) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationOverride]) -> [AuthorizationOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationOverrides(_ store: any AuthorizationOverrideStore, query: AuthorizationOverrideQuery) -> [AuthorizationOverride] {
        return query.apply(store.list())
    }
}
