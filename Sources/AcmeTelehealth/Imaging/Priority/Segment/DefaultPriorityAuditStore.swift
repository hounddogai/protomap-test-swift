import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps default priority audits by code.
    protocol DefaultPriorityAuditStore {
        func find(_ code: String) -> DefaultPriorityAudit?
        func save(_ item: DefaultPriorityAudit)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultPriorityAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultPriorityAuditStore: DefaultPriorityAuditStore {
        var items: [String: DefaultPriorityAudit]
        var order: [String]

        init(items: [String: DefaultPriorityAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultPriorityAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultPriorityAudit) {
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

        func list() -> [DefaultPriorityAudit] {
            var out: [DefaultPriorityAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultPriorityAuditStore() -> any DefaultPriorityAuditStore {
        return MemoryDefaultPriorityAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultPriorityAuditStore: DefaultPriorityAuditStore {
        var inner: MemoryDefaultPriorityAuditStore
        var cache: TTLCache<DefaultPriorityAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultPriorityAuditStore, cache: TTLCache<DefaultPriorityAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultPriorityAudit? {
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

        func save(_ item: DefaultPriorityAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultPriorityAudit] {
            return inner.list()
        }
    }

    static func newCachedDefaultPriorityAuditStore(_ inner: MemoryDefaultPriorityAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultPriorityAuditStore {
        return CachedDefaultPriorityAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default priority audits. Empty fields match all.
    final class DefaultPriorityAuditQuery {
        var source: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minVersion: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultPriorityAudit) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultPriorityAudit]) -> [DefaultPriorityAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultPriorityAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultPriorityAudits(_ store: any DefaultPriorityAuditStore, query: DefaultPriorityAuditQuery) -> [DefaultPriorityAudit] {
        return query.apply(store.list())
    }
}
