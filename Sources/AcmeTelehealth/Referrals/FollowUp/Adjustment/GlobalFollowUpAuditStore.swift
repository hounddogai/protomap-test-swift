import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps global follow up audits by code.
    protocol GlobalFollowUpAuditStore {
        func find(_ code: String) -> GlobalFollowUpAudit?
        func save(_ item: GlobalFollowUpAudit)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalFollowUpAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalFollowUpAuditStore: GlobalFollowUpAuditStore {
        var items: [String: GlobalFollowUpAudit]
        var order: [String]

        init(items: [String: GlobalFollowUpAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalFollowUpAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalFollowUpAudit) {
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

        func list() -> [GlobalFollowUpAudit] {
            var out: [GlobalFollowUpAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalFollowUpAuditStore() -> any GlobalFollowUpAuditStore {
        return MemoryGlobalFollowUpAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalFollowUpAuditStore: GlobalFollowUpAuditStore {
        var inner: MemoryGlobalFollowUpAuditStore
        var cache: TTLCache<GlobalFollowUpAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalFollowUpAuditStore, cache: TTLCache<GlobalFollowUpAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalFollowUpAudit? {
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

        func save(_ item: GlobalFollowUpAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalFollowUpAudit] {
            return inner.list()
        }
    }

    static func newCachedGlobalFollowUpAuditStore(_ inner: MemoryGlobalFollowUpAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalFollowUpAuditStore {
        return CachedGlobalFollowUpAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global follow up audits. Empty fields match all.
    final class GlobalFollowUpAuditQuery {
        var unit: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalFollowUpAudit) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalFollowUpAudit]) -> [GlobalFollowUpAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalFollowUpAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalFollowUpAudits(_ store: any GlobalFollowUpAuditStore, query: GlobalFollowUpAuditQuery) -> [GlobalFollowUpAudit] {
        return query.apply(store.list())
    }
}
