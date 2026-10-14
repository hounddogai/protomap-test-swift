import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime audits by code.
    protocol OvertimeAuditStore {
        func find(_ code: String) -> OvertimeAudit?
        func save(_ item: OvertimeAudit)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeAuditStore: OvertimeAuditStore {
        var items: [String: OvertimeAudit]
        var order: [String]

        init(items: [String: OvertimeAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeAudit) {
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

        func list() -> [OvertimeAudit] {
            var out: [OvertimeAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeAuditStore() -> any OvertimeAuditStore {
        return MemoryOvertimeAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeAuditStore: OvertimeAuditStore {
        var inner: MemoryOvertimeAuditStore
        var cache: TTLCache<OvertimeAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeAuditStore, cache: TTLCache<OvertimeAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeAudit? {
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

        func save(_ item: OvertimeAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeAudit] {
            return inner.list()
        }
    }

    static func newCachedOvertimeAuditStore(_ inner: MemoryOvertimeAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeAuditStore {
        return CachedOvertimeAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime audits. Empty fields match all.
    final class OvertimeAuditQuery {
        var facility: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRetries: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeAudit) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeAudit]) -> [OvertimeAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeAudits(_ store: any OvertimeAuditStore, query: OvertimeAuditQuery) -> [OvertimeAudit] {
        return query.apply(store.list())
    }
}
