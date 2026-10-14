import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization tiers by code.
    protocol AuthorizationTierStore {
        func find(_ code: String) -> AuthorizationTier?
        func save(_ item: AuthorizationTier)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationTierStore: AuthorizationTierStore {
        var items: [String: AuthorizationTier]
        var order: [String]

        init(items: [String: AuthorizationTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationTier) {
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

        func list() -> [AuthorizationTier] {
            var out: [AuthorizationTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationTierStore() -> any AuthorizationTierStore {
        return MemoryAuthorizationTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationTierStore: AuthorizationTierStore {
        var inner: MemoryAuthorizationTierStore
        var cache: TTLCache<AuthorizationTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationTierStore, cache: TTLCache<AuthorizationTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationTier? {
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

        func save(_ item: AuthorizationTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationTier] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationTierStore(_ inner: MemoryAuthorizationTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationTierStore {
        return CachedAuthorizationTierStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization tiers. Empty fields match all.
    final class AuthorizationTierQuery {
        var unit: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minScore: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationTier) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationTier]) -> [AuthorizationTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationTiers(_ store: any AuthorizationTierStore, query: AuthorizationTierQuery) -> [AuthorizationTier] {
        return query.apply(store.list())
    }
}
