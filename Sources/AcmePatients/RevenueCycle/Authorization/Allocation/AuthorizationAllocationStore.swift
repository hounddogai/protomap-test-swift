import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization allocations by code.
    protocol AuthorizationAllocationStore {
        func find(_ code: String) -> AuthorizationAllocation?
        func save(_ item: AuthorizationAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationAllocationStore: AuthorizationAllocationStore {
        var items: [String: AuthorizationAllocation]
        var order: [String]

        init(items: [String: AuthorizationAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationAllocation) {
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

        func list() -> [AuthorizationAllocation] {
            var out: [AuthorizationAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationAllocationStore() -> any AuthorizationAllocationStore {
        return MemoryAuthorizationAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationAllocationStore: AuthorizationAllocationStore {
        var inner: MemoryAuthorizationAllocationStore
        var cache: TTLCache<AuthorizationAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationAllocationStore, cache: TTLCache<AuthorizationAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationAllocation? {
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

        func save(_ item: AuthorizationAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationAllocation] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationAllocationStore(_ inner: MemoryAuthorizationAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationAllocationStore {
        return CachedAuthorizationAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization allocations. Empty fields match all.
    final class AuthorizationAllocationQuery {
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

        func matches(_ item: AuthorizationAllocation) -> Bool {
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

        func apply(_ items: [AuthorizationAllocation]) -> [AuthorizationAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationAllocations(_ store: any AuthorizationAllocationStore, query: AuthorizationAllocationQuery) -> [AuthorizationAllocation] {
        return query.apply(store.list())
    }
}
