import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization rollups by code.
    protocol AuthorizationRollupStore {
        func find(_ code: String) -> AuthorizationRollup?
        func save(_ item: AuthorizationRollup)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationRollupStore: AuthorizationRollupStore {
        var items: [String: AuthorizationRollup]
        var order: [String]

        init(items: [String: AuthorizationRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationRollup) {
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

        func list() -> [AuthorizationRollup] {
            var out: [AuthorizationRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationRollupStore() -> any AuthorizationRollupStore {
        return MemoryAuthorizationRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationRollupStore: AuthorizationRollupStore {
        var inner: MemoryAuthorizationRollupStore
        var cache: TTLCache<AuthorizationRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationRollupStore, cache: TTLCache<AuthorizationRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationRollup? {
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

        func save(_ item: AuthorizationRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationRollup] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationRollupStore(_ inner: MemoryAuthorizationRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationRollupStore {
        return CachedAuthorizationRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization rollups. Empty fields match all.
    final class AuthorizationRollupQuery {
        var facility: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minVersion: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationRollup) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationRollup]) -> [AuthorizationRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationRollups(_ store: any AuthorizationRollupStore, query: AuthorizationRollupQuery) -> [AuthorizationRollup] {
        return query.apply(store.list())
    }
}
