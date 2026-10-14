import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy audits by code.
    protocol ProxyAuditStore {
        func find(_ code: String) -> ProxyAudit?
        func save(_ item: ProxyAudit)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyAuditStore: ProxyAuditStore {
        var items: [String: ProxyAudit]
        var order: [String]

        init(items: [String: ProxyAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyAudit) {
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

        func list() -> [ProxyAudit] {
            var out: [ProxyAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyAuditStore() -> any ProxyAuditStore {
        return MemoryProxyAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyAuditStore: ProxyAuditStore {
        var inner: MemoryProxyAuditStore
        var cache: TTLCache<ProxyAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyAuditStore, cache: TTLCache<ProxyAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyAudit? {
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

        func save(_ item: ProxyAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyAudit] {
            return inner.list()
        }
    }

    static func newCachedProxyAuditStore(_ inner: MemoryProxyAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyAuditStore {
        return CachedProxyAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy audits. Empty fields match all.
    final class ProxyAuditQuery {
        var facility: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRefills: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyAudit) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [ProxyAudit]) -> [ProxyAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyAudits(_ store: any ProxyAuditStore, query: ProxyAuditQuery) -> [ProxyAudit] {
        return query.apply(store.list())
    }
}
