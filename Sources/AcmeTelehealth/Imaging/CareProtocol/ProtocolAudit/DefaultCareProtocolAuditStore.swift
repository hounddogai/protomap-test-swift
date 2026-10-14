import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps default care protocol audits by code.
    protocol DefaultCareProtocolAuditStore {
        func find(_ code: String) -> DefaultCareProtocolAudit?
        func save(_ item: DefaultCareProtocolAudit)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultCareProtocolAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultCareProtocolAuditStore: DefaultCareProtocolAuditStore {
        var items: [String: DefaultCareProtocolAudit]
        var order: [String]

        init(items: [String: DefaultCareProtocolAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultCareProtocolAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultCareProtocolAudit) {
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

        func list() -> [DefaultCareProtocolAudit] {
            var out: [DefaultCareProtocolAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultCareProtocolAuditStore() -> any DefaultCareProtocolAuditStore {
        return MemoryDefaultCareProtocolAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultCareProtocolAuditStore: DefaultCareProtocolAuditStore {
        var inner: MemoryDefaultCareProtocolAuditStore
        var cache: TTLCache<DefaultCareProtocolAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultCareProtocolAuditStore, cache: TTLCache<DefaultCareProtocolAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultCareProtocolAudit? {
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

        func save(_ item: DefaultCareProtocolAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultCareProtocolAudit] {
            return inner.list()
        }
    }

    static func newCachedDefaultCareProtocolAuditStore(_ inner: MemoryDefaultCareProtocolAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultCareProtocolAuditStore {
        return CachedDefaultCareProtocolAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default care protocol audits. Empty fields match all.
    final class DefaultCareProtocolAuditQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultCareProtocolAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultCareProtocolAudit]) -> [DefaultCareProtocolAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultCareProtocolAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultCareProtocolAudits(_ store: any DefaultCareProtocolAuditStore, query: DefaultCareProtocolAuditQuery) -> [DefaultCareProtocolAudit] {
        return query.apply(store.list())
    }
}
