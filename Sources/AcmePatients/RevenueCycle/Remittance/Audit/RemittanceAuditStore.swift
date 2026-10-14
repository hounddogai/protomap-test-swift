import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance audits by code.
    protocol RemittanceAuditStore {
        func find(_ code: String) -> RemittanceAudit?
        func save(_ item: RemittanceAudit)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceAuditStore: RemittanceAuditStore {
        var items: [String: RemittanceAudit]
        var order: [String]

        init(items: [String: RemittanceAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceAudit) {
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

        func list() -> [RemittanceAudit] {
            var out: [RemittanceAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceAuditStore() -> any RemittanceAuditStore {
        return MemoryRemittanceAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceAuditStore: RemittanceAuditStore {
        var inner: MemoryRemittanceAuditStore
        var cache: TTLCache<RemittanceAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceAuditStore, cache: TTLCache<RemittanceAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceAudit? {
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

        func save(_ item: RemittanceAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceAudit] {
            return inner.list()
        }
    }

    static func newCachedRemittanceAuditStore(_ inner: MemoryRemittanceAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceAuditStore {
        return CachedRemittanceAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance audits. Empty fields match all.
    final class RemittanceAuditQuery {
        var country: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceAudit) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceAudit]) -> [RemittanceAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceAudits(_ store: any RemittanceAuditStore, query: RemittanceAuditQuery) -> [RemittanceAudit] {
        return query.apply(store.list())
    }
}
