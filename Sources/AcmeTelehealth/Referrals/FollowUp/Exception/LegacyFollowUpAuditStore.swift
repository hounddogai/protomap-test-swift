import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps legacy follow up audits by code.
    protocol LegacyFollowUpAuditStore {
        func find(_ code: String) -> LegacyFollowUpAudit?
        func save(_ item: LegacyFollowUpAudit)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyFollowUpAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyFollowUpAuditStore: LegacyFollowUpAuditStore {
        var items: [String: LegacyFollowUpAudit]
        var order: [String]

        init(items: [String: LegacyFollowUpAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyFollowUpAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyFollowUpAudit) {
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

        func list() -> [LegacyFollowUpAudit] {
            var out: [LegacyFollowUpAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyFollowUpAuditStore() -> any LegacyFollowUpAuditStore {
        return MemoryLegacyFollowUpAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyFollowUpAuditStore: LegacyFollowUpAuditStore {
        var inner: MemoryLegacyFollowUpAuditStore
        var cache: TTLCache<LegacyFollowUpAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyFollowUpAuditStore, cache: TTLCache<LegacyFollowUpAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyFollowUpAudit? {
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

        func save(_ item: LegacyFollowUpAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyFollowUpAudit] {
            return inner.list()
        }
    }

    static func newCachedLegacyFollowUpAuditStore(_ inner: MemoryLegacyFollowUpAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyFollowUpAuditStore {
        return CachedLegacyFollowUpAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy follow up audits. Empty fields match all.
    final class LegacyFollowUpAuditQuery {
        var label: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyFollowUpAudit) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyFollowUpAudit]) -> [LegacyFollowUpAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyFollowUpAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyFollowUpAudits(_ store: any LegacyFollowUpAuditStore, query: LegacyFollowUpAuditQuery) -> [LegacyFollowUpAudit] {
        return query.apply(store.list())
    }
}
