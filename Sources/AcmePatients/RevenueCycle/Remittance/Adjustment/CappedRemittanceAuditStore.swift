import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped remittance audits by code.
    protocol CappedRemittanceAuditStore {
        func find(_ code: String) -> CappedRemittanceAudit?
        func save(_ item: CappedRemittanceAudit)
        func remove(_ code: String) -> Bool
        func list() -> [CappedRemittanceAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedRemittanceAuditStore: CappedRemittanceAuditStore {
        var items: [String: CappedRemittanceAudit]
        var order: [String]

        init(items: [String: CappedRemittanceAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedRemittanceAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedRemittanceAudit) {
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

        func list() -> [CappedRemittanceAudit] {
            var out: [CappedRemittanceAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedRemittanceAuditStore() -> any CappedRemittanceAuditStore {
        return MemoryCappedRemittanceAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedRemittanceAuditStore: CappedRemittanceAuditStore {
        var inner: MemoryCappedRemittanceAuditStore
        var cache: TTLCache<CappedRemittanceAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedRemittanceAuditStore, cache: TTLCache<CappedRemittanceAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedRemittanceAudit? {
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

        func save(_ item: CappedRemittanceAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedRemittanceAudit] {
            return inner.list()
        }
    }

    static func newCachedCappedRemittanceAuditStore(_ inner: MemoryCappedRemittanceAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedRemittanceAuditStore {
        return CachedCappedRemittanceAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped remittance audits. Empty fields match all.
    final class CappedRemittanceAuditQuery {
        var ward: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedRemittanceAudit) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [CappedRemittanceAudit]) -> [CappedRemittanceAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedRemittanceAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedRemittanceAudits(_ store: any CappedRemittanceAuditStore, query: CappedRemittanceAuditQuery) -> [CappedRemittanceAudit] {
        return query.apply(store.list())
    }
}
