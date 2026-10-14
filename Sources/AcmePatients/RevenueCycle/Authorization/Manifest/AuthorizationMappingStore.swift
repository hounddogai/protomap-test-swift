import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization mappings by code.
    protocol AuthorizationMappingStore {
        func find(_ code: String) -> AuthorizationMapping?
        func save(_ item: AuthorizationMapping)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationMappingStore: AuthorizationMappingStore {
        var items: [String: AuthorizationMapping]
        var order: [String]

        init(items: [String: AuthorizationMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationMapping) {
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

        func list() -> [AuthorizationMapping] {
            var out: [AuthorizationMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationMappingStore() -> any AuthorizationMappingStore {
        return MemoryAuthorizationMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationMappingStore: AuthorizationMappingStore {
        var inner: MemoryAuthorizationMappingStore
        var cache: TTLCache<AuthorizationMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationMappingStore, cache: TTLCache<AuthorizationMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationMapping? {
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

        func save(_ item: AuthorizationMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationMapping] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationMappingStore(_ inner: MemoryAuthorizationMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationMappingStore {
        return CachedAuthorizationMappingStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization mappings. Empty fields match all.
    final class AuthorizationMappingQuery {
        var region: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationMapping) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationMapping]) -> [AuthorizationMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationMappings(_ store: any AuthorizationMappingStore, query: AuthorizationMappingQuery) -> [AuthorizationMapping] {
        return query.apply(store.list())
    }
}
