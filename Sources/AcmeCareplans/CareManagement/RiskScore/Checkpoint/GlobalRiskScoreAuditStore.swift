import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global risk score audits by code.
    protocol GlobalRiskScoreAuditStore {
        func find(_ code: String) -> GlobalRiskScoreAudit?
        func save(_ item: GlobalRiskScoreAudit)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalRiskScoreAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalRiskScoreAuditStore: GlobalRiskScoreAuditStore {
        var items: [String: GlobalRiskScoreAudit]
        var order: [String]

        init(items: [String: GlobalRiskScoreAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalRiskScoreAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalRiskScoreAudit) {
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

        func list() -> [GlobalRiskScoreAudit] {
            var out: [GlobalRiskScoreAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalRiskScoreAuditStore() -> any GlobalRiskScoreAuditStore {
        return MemoryGlobalRiskScoreAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalRiskScoreAuditStore: GlobalRiskScoreAuditStore {
        var inner: MemoryGlobalRiskScoreAuditStore
        var cache: TTLCache<GlobalRiskScoreAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalRiskScoreAuditStore, cache: TTLCache<GlobalRiskScoreAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalRiskScoreAudit? {
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

        func save(_ item: GlobalRiskScoreAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalRiskScoreAudit] {
            return inner.list()
        }
    }

    static func newCachedGlobalRiskScoreAuditStore(_ inner: MemoryGlobalRiskScoreAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalRiskScoreAuditStore {
        return CachedGlobalRiskScoreAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global risk score audits. Empty fields match all.
    final class GlobalRiskScoreAuditQuery {
        var unit: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalRiskScoreAudit) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [GlobalRiskScoreAudit]) -> [GlobalRiskScoreAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalRiskScoreAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalRiskScoreAudits(_ store: any GlobalRiskScoreAuditStore, query: GlobalRiskScoreAuditQuery) -> [GlobalRiskScoreAudit] {
        return query.apply(store.list())
    }
}
