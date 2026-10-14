import AcmePlatform
import Foundation

extension Consent {
    /// Keeps global proxy audits by code.
    protocol GlobalProxyAuditStore {
        func find(_ code: String) -> GlobalProxyAudit?
        func save(_ item: GlobalProxyAudit)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalProxyAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalProxyAuditStore: GlobalProxyAuditStore {
        var items: [String: GlobalProxyAudit]
        var order: [String]

        init(items: [String: GlobalProxyAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalProxyAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalProxyAudit) {
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

        func list() -> [GlobalProxyAudit] {
            var out: [GlobalProxyAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalProxyAuditStore() -> any GlobalProxyAuditStore {
        return MemoryGlobalProxyAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalProxyAuditStore: GlobalProxyAuditStore {
        var inner: MemoryGlobalProxyAuditStore
        var cache: TTLCache<GlobalProxyAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalProxyAuditStore, cache: TTLCache<GlobalProxyAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalProxyAudit? {
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

        func save(_ item: GlobalProxyAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalProxyAudit] {
            return inner.list()
        }
    }

    static func newCachedGlobalProxyAuditStore(_ inner: MemoryGlobalProxyAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalProxyAuditStore {
        return CachedGlobalProxyAuditStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global proxy audits. Empty fields match all.
    final class GlobalProxyAuditQuery {
        var region: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minSequence: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalProxyAudit) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [GlobalProxyAudit]) -> [GlobalProxyAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalProxyAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalProxyAudits(_ store: any GlobalProxyAuditStore, query: GlobalProxyAuditQuery) -> [GlobalProxyAudit] {
        return query.apply(store.list())
    }
}
