import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps strict follow up audits by code.
    protocol StrictFollowUpAuditStore {
        func find(_ code: String) -> StrictFollowUpAudit?
        func save(_ item: StrictFollowUpAudit)
        func remove(_ code: String) -> Bool
        func list() -> [StrictFollowUpAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictFollowUpAuditStore: StrictFollowUpAuditStore {
        var items: [String: StrictFollowUpAudit]
        var order: [String]

        init(items: [String: StrictFollowUpAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictFollowUpAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictFollowUpAudit) {
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

        func list() -> [StrictFollowUpAudit] {
            var out: [StrictFollowUpAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictFollowUpAuditStore() -> any StrictFollowUpAuditStore {
        return MemoryStrictFollowUpAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictFollowUpAuditStore: StrictFollowUpAuditStore {
        var inner: MemoryStrictFollowUpAuditStore
        var cache: TTLCache<StrictFollowUpAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictFollowUpAuditStore, cache: TTLCache<StrictFollowUpAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictFollowUpAudit? {
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

        func save(_ item: StrictFollowUpAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictFollowUpAudit] {
            return inner.list()
        }
    }

    static func newCachedStrictFollowUpAuditStore(_ inner: MemoryStrictFollowUpAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictFollowUpAuditStore {
        return CachedStrictFollowUpAuditStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict follow up audits. Empty fields match all.
    final class StrictFollowUpAuditQuery {
        var ward: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCost: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictFollowUpAudit) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [StrictFollowUpAudit]) -> [StrictFollowUpAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictFollowUpAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictFollowUpAudits(_ store: any StrictFollowUpAuditStore, query: StrictFollowUpAuditQuery) -> [StrictFollowUpAudit] {
        return query.apply(store.list())
    }
}
