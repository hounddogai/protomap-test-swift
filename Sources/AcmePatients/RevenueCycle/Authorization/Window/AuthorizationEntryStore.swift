import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization entries by code.
    protocol AuthorizationEntryStore {
        func find(_ code: String) -> AuthorizationEntry?
        func save(_ item: AuthorizationEntry)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationEntry]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationEntryStore: AuthorizationEntryStore {
        var items: [String: AuthorizationEntry]
        var order: [String]

        init(items: [String: AuthorizationEntry], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationEntry? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationEntry) {
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

        func list() -> [AuthorizationEntry] {
            var out: [AuthorizationEntry] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationEntryStore() -> any AuthorizationEntryStore {
        return MemoryAuthorizationEntryStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationEntryStore: AuthorizationEntryStore {
        var inner: MemoryAuthorizationEntryStore
        var cache: TTLCache<AuthorizationEntry>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationEntryStore, cache: TTLCache<AuthorizationEntry>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationEntry? {
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

        func save(_ item: AuthorizationEntry) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationEntry] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationEntryStore(_ inner: MemoryAuthorizationEntryStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationEntryStore {
        return CachedAuthorizationEntryStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization entries. Empty fields match all.
    final class AuthorizationEntryQuery {
        var facility: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationEntry) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationEntry]) -> [AuthorizationEntry] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationEntry) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationEntries(_ store: any AuthorizationEntryStore, query: AuthorizationEntryQuery) -> [AuthorizationEntry] {
        return query.apply(store.list())
    }
}
