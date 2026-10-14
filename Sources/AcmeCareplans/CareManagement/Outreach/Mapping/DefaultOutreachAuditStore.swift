import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps default outreach audits by code.
    protocol DefaultOutreachAuditStore {
        func find(_ code: String) -> DefaultOutreachAudit?
        func save(_ item: DefaultOutreachAudit)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultOutreachAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultOutreachAuditStore: DefaultOutreachAuditStore {
        var items: [String: DefaultOutreachAudit]
        var order: [String]

        init(items: [String: DefaultOutreachAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultOutreachAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultOutreachAudit) {
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

        func list() -> [DefaultOutreachAudit] {
            var out: [DefaultOutreachAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultOutreachAuditStore() -> any DefaultOutreachAuditStore {
        return MemoryDefaultOutreachAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultOutreachAuditStore: DefaultOutreachAuditStore {
        var inner: MemoryDefaultOutreachAuditStore
        var cache: TTLCache<DefaultOutreachAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultOutreachAuditStore, cache: TTLCache<DefaultOutreachAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultOutreachAudit? {
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

        func save(_ item: DefaultOutreachAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultOutreachAudit] {
            return inner.list()
        }
    }

    static func newCachedDefaultOutreachAuditStore(_ inner: MemoryDefaultOutreachAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultOutreachAuditStore {
        return CachedDefaultOutreachAuditStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default outreach audits. Empty fields match all.
    final class DefaultOutreachAuditQuery {
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

        func matches(_ item: DefaultOutreachAudit) -> Bool {
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

        func apply(_ items: [DefaultOutreachAudit]) -> [DefaultOutreachAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultOutreachAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultOutreachAudits(_ store: any DefaultOutreachAuditStore, query: DefaultOutreachAuditQuery) -> [DefaultOutreachAudit] {
        return query.apply(store.list())
    }
}
