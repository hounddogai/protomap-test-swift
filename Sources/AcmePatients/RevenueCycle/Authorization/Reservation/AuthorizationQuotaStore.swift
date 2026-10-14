import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization quotas by code.
    protocol AuthorizationQuotaStore {
        func find(_ code: String) -> AuthorizationQuota?
        func save(_ item: AuthorizationQuota)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationQuotaStore: AuthorizationQuotaStore {
        var items: [String: AuthorizationQuota]
        var order: [String]

        init(items: [String: AuthorizationQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationQuota) {
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

        func list() -> [AuthorizationQuota] {
            var out: [AuthorizationQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationQuotaStore() -> any AuthorizationQuotaStore {
        return MemoryAuthorizationQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationQuotaStore: AuthorizationQuotaStore {
        var inner: MemoryAuthorizationQuotaStore
        var cache: TTLCache<AuthorizationQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationQuotaStore, cache: TTLCache<AuthorizationQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationQuota? {
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

        func save(_ item: AuthorizationQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationQuota] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationQuotaStore(_ inner: MemoryAuthorizationQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationQuotaStore {
        return CachedAuthorizationQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization quotas. Empty fields match all.
    final class AuthorizationQuotaQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationQuota) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationQuota]) -> [AuthorizationQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationQuotas(_ store: any AuthorizationQuotaStore, query: AuthorizationQuotaQuery) -> [AuthorizationQuota] {
        return query.apply(store.list())
    }
}
