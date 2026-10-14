import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps risk score audits by code.
    protocol RiskScoreAuditStore {
        func find(_ code: String) -> RiskScoreAudit?
        func save(_ item: RiskScoreAudit)
        func remove(_ code: String) -> Bool
        func list() -> [RiskScoreAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRiskScoreAuditStore: RiskScoreAuditStore {
        var items: [String: RiskScoreAudit]
        var order: [String]

        init(items: [String: RiskScoreAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RiskScoreAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RiskScoreAudit) {
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

        func list() -> [RiskScoreAudit] {
            var out: [RiskScoreAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRiskScoreAuditStore() -> any RiskScoreAuditStore {
        return MemoryRiskScoreAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRiskScoreAuditStore: RiskScoreAuditStore {
        var inner: MemoryRiskScoreAuditStore
        var cache: TTLCache<RiskScoreAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryRiskScoreAuditStore, cache: TTLCache<RiskScoreAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RiskScoreAudit? {
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

        func save(_ item: RiskScoreAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RiskScoreAudit] {
            return inner.list()
        }
    }

    static func newCachedRiskScoreAuditStore(_ inner: MemoryRiskScoreAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RiskScoreAuditStore {
        return CachedRiskScoreAuditStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects risk score audits. Empty fields match all.
    final class RiskScoreAuditQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RiskScoreAudit) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RiskScoreAudit]) -> [RiskScoreAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RiskScoreAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRiskScoreAudits(_ store: any RiskScoreAuditStore, query: RiskScoreAuditQuery) -> [RiskScoreAudit] {
        return query.apply(store.list())
    }
}
