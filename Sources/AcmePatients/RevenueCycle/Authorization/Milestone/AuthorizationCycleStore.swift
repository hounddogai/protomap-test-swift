import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization cycles by code.
    protocol AuthorizationCycleStore {
        func find(_ code: String) -> AuthorizationCycle?
        func save(_ item: AuthorizationCycle)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationCycleStore: AuthorizationCycleStore {
        var items: [String: AuthorizationCycle]
        var order: [String]

        init(items: [String: AuthorizationCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationCycle) {
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

        func list() -> [AuthorizationCycle] {
            var out: [AuthorizationCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationCycleStore() -> any AuthorizationCycleStore {
        return MemoryAuthorizationCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationCycleStore: AuthorizationCycleStore {
        var inner: MemoryAuthorizationCycleStore
        var cache: TTLCache<AuthorizationCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationCycleStore, cache: TTLCache<AuthorizationCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationCycle? {
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

        func save(_ item: AuthorizationCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationCycle] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationCycleStore(_ inner: MemoryAuthorizationCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationCycleStore {
        return CachedAuthorizationCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization cycles. Empty fields match all.
    final class AuthorizationCycleQuery {
        var name: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRevision: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationCycle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationCycle]) -> [AuthorizationCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationCycles(_ store: any AuthorizationCycleStore, query: AuthorizationCycleQuery) -> [AuthorizationCycle] {
        return query.apply(store.list())
    }
}
