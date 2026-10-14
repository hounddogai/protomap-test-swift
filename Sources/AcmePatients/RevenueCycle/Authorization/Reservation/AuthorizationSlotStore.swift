import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization slots by code.
    protocol AuthorizationSlotStore {
        func find(_ code: String) -> AuthorizationSlot?
        func save(_ item: AuthorizationSlot)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationSlotStore: AuthorizationSlotStore {
        var items: [String: AuthorizationSlot]
        var order: [String]

        init(items: [String: AuthorizationSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationSlot) {
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

        func list() -> [AuthorizationSlot] {
            var out: [AuthorizationSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationSlotStore() -> any AuthorizationSlotStore {
        return MemoryAuthorizationSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationSlotStore: AuthorizationSlotStore {
        var inner: MemoryAuthorizationSlotStore
        var cache: TTLCache<AuthorizationSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationSlotStore, cache: TTLCache<AuthorizationSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationSlot? {
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

        func save(_ item: AuthorizationSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationSlot] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationSlotStore(_ inner: MemoryAuthorizationSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationSlotStore {
        return CachedAuthorizationSlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization slots. Empty fields match all.
    final class AuthorizationSlotQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationSlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [AuthorizationSlot]) -> [AuthorizationSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationSlots(_ store: any AuthorizationSlotStore, query: AuthorizationSlotQuery) -> [AuthorizationSlot] {
        return query.apply(store.list())
    }
}
