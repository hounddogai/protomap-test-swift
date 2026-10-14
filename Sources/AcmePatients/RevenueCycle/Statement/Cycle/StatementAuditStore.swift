import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement audits by code.
    protocol StatementAuditStore {
        func find(_ code: String) -> StatementAudit?
        func save(_ item: StatementAudit)
        func remove(_ code: String) -> Bool
        func list() -> [StatementAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementAuditStore: StatementAuditStore {
        var items: [String: StatementAudit]
        var order: [String]

        init(items: [String: StatementAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementAudit) {
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

        func list() -> [StatementAudit] {
            var out: [StatementAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementAuditStore() -> any StatementAuditStore {
        return MemoryStatementAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementAuditStore: StatementAuditStore {
        var inner: MemoryStatementAuditStore
        var cache: TTLCache<StatementAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementAuditStore, cache: TTLCache<StatementAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementAudit? {
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

        func save(_ item: StatementAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementAudit] {
            return inner.list()
        }
    }

    static func newCachedStatementAuditStore(_ inner: MemoryStatementAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementAuditStore {
        return CachedStatementAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement audits. Empty fields match all.
    final class StatementAuditQuery {
        var region: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minScore: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementAudit) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementAudit]) -> [StatementAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementAudits(_ store: any StatementAuditStore, query: StatementAuditQuery) -> [StatementAudit] {
        return query.apply(store.list())
    }
}
