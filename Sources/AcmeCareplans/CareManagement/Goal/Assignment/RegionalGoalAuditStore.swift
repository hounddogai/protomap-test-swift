import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps regional goal audits by code.
    protocol RegionalGoalAuditStore {
        func find(_ code: String) -> RegionalGoalAudit?
        func save(_ item: RegionalGoalAudit)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalGoalAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalGoalAuditStore: RegionalGoalAuditStore {
        var items: [String: RegionalGoalAudit]
        var order: [String]

        init(items: [String: RegionalGoalAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalGoalAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalGoalAudit) {
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

        func list() -> [RegionalGoalAudit] {
            var out: [RegionalGoalAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalGoalAuditStore() -> any RegionalGoalAuditStore {
        return MemoryRegionalGoalAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalGoalAuditStore: RegionalGoalAuditStore {
        var inner: MemoryRegionalGoalAuditStore
        var cache: TTLCache<RegionalGoalAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalGoalAuditStore, cache: TTLCache<RegionalGoalAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalGoalAudit? {
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

        func save(_ item: RegionalGoalAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalGoalAudit] {
            return inner.list()
        }
    }

    static func newCachedRegionalGoalAuditStore(_ inner: MemoryRegionalGoalAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalGoalAuditStore {
        return CachedRegionalGoalAuditStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional goal audits. Empty fields match all.
    final class RegionalGoalAuditQuery {
        var label: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVersion: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalGoalAudit) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [RegionalGoalAudit]) -> [RegionalGoalAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalGoalAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalGoalAudits(_ store: any RegionalGoalAuditStore, query: RegionalGoalAuditQuery) -> [RegionalGoalAudit] {
        return query.apply(store.list())
    }
}
