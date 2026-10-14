import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization audits by code.
    protocol AuthorizationAuditStore {
        func find(_ code: String) -> AuthorizationAudit?
        func save(_ item: AuthorizationAudit)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationAuditStore: AuthorizationAuditStore {
        var items: [String: AuthorizationAudit]
        var order: [String]

        init(items: [String: AuthorizationAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationAudit) {
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

        func list() -> [AuthorizationAudit] {
            var out: [AuthorizationAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationAuditStore() -> any AuthorizationAuditStore {
        return MemoryAuthorizationAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationAuditStore: AuthorizationAuditStore {
        var inner: MemoryAuthorizationAuditStore
        var cache: TTLCache<AuthorizationAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationAuditStore, cache: TTLCache<AuthorizationAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationAudit? {
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

        func save(_ item: AuthorizationAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationAudit] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationAuditStore(_ inner: MemoryAuthorizationAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationAuditStore {
        return CachedAuthorizationAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization audits. Empty fields match all.
    final class AuthorizationAuditQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationAudit) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationAudit]) -> [AuthorizationAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationAudits(_ store: any AuthorizationAuditStore, query: AuthorizationAuditQuery) -> [AuthorizationAudit] {
        return query.apply(store.list())
    }
}
