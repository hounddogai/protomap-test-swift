import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization windows by code.
    protocol AuthorizationWindowStore {
        func find(_ code: String) -> AuthorizationWindow?
        func save(_ item: AuthorizationWindow)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationWindow]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationWindowStore: AuthorizationWindowStore {
        var items: [String: AuthorizationWindow]
        var order: [String]

        init(items: [String: AuthorizationWindow], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationWindow? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationWindow) {
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

        func list() -> [AuthorizationWindow] {
            var out: [AuthorizationWindow] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationWindowStore() -> any AuthorizationWindowStore {
        return MemoryAuthorizationWindowStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationWindowStore: AuthorizationWindowStore {
        var inner: MemoryAuthorizationWindowStore
        var cache: TTLCache<AuthorizationWindow>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationWindowStore, cache: TTLCache<AuthorizationWindow>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationWindow? {
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

        func save(_ item: AuthorizationWindow) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationWindow] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationWindowStore(_ inner: MemoryAuthorizationWindowStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationWindowStore {
        return CachedAuthorizationWindowStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization windows. Empty fields match all.
    final class AuthorizationWindowQuery {
        var country: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRatio: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationWindow) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationWindow]) -> [AuthorizationWindow] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationWindow) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationWindows(_ store: any AuthorizationWindowStore, query: AuthorizationWindowQuery) -> [AuthorizationWindow] {
        return query.apply(store.list())
    }
}
