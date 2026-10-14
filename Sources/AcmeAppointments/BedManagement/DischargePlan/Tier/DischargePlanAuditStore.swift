import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan audits by code.
    protocol DischargePlanAuditStore {
        func find(_ code: String) -> DischargePlanAudit?
        func save(_ item: DischargePlanAudit)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanAuditStore: DischargePlanAuditStore {
        var items: [String: DischargePlanAudit]
        var order: [String]

        init(items: [String: DischargePlanAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanAudit) {
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

        func list() -> [DischargePlanAudit] {
            var out: [DischargePlanAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanAuditStore() -> any DischargePlanAuditStore {
        return MemoryDischargePlanAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanAuditStore: DischargePlanAuditStore {
        var inner: MemoryDischargePlanAuditStore
        var cache: TTLCache<DischargePlanAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanAuditStore, cache: TTLCache<DischargePlanAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanAudit? {
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

        func save(_ item: DischargePlanAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanAudit] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanAuditStore(_ inner: MemoryDischargePlanAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanAuditStore {
        return CachedDischargePlanAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan audits. Empty fields match all.
    final class DischargePlanAuditQuery {
        var title: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCost: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanAudit]) -> [DischargePlanAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanAudits(_ store: any DischargePlanAuditStore, query: DischargePlanAuditQuery) -> [DischargePlanAudit] {
        return query.apply(store.list())
    }
}
