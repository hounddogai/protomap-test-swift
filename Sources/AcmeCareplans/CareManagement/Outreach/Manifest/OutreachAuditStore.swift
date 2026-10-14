import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach audits by code.
    protocol OutreachAuditStore {
        func find(_ code: String) -> OutreachAudit?
        func save(_ item: OutreachAudit)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachAuditStore: OutreachAuditStore {
        var items: [String: OutreachAudit]
        var order: [String]

        init(items: [String: OutreachAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachAudit) {
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

        func list() -> [OutreachAudit] {
            var out: [OutreachAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachAuditStore() -> any OutreachAuditStore {
        return MemoryOutreachAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachAuditStore: OutreachAuditStore {
        var inner: MemoryOutreachAuditStore
        var cache: TTLCache<OutreachAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachAuditStore, cache: TTLCache<OutreachAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachAudit? {
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

        func save(_ item: OutreachAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachAudit] {
            return inner.list()
        }
    }

    static func newCachedOutreachAuditStore(_ inner: MemoryOutreachAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachAuditStore {
        return CachedOutreachAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach audits. Empty fields match all.
    final class OutreachAuditQuery {
        var channel: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachAudit) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OutreachAudit]) -> [OutreachAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachAudits(_ store: any OutreachAuditStore, query: OutreachAuditQuery) -> [OutreachAudit] {
        return query.apply(store.list())
    }
}
