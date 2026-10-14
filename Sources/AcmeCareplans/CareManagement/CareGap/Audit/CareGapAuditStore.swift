import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap audits by code.
    protocol CareGapAuditStore {
        func find(_ code: String) -> CareGapAudit?
        func save(_ item: CareGapAudit)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapAuditStore: CareGapAuditStore {
        var items: [String: CareGapAudit]
        var order: [String]

        init(items: [String: CareGapAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapAudit) {
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

        func list() -> [CareGapAudit] {
            var out: [CareGapAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapAuditStore() -> any CareGapAuditStore {
        return MemoryCareGapAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapAuditStore: CareGapAuditStore {
        var inner: MemoryCareGapAuditStore
        var cache: TTLCache<CareGapAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapAuditStore, cache: TTLCache<CareGapAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapAudit? {
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

        func save(_ item: CareGapAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapAudit] {
            return inner.list()
        }
    }

    static func newCachedCareGapAuditStore(_ inner: MemoryCareGapAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapAuditStore {
        return CachedCareGapAuditStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap audits. Empty fields match all.
    final class CareGapAuditQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapAudit) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareGapAudit]) -> [CareGapAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapAudits(_ store: any CareGapAuditStore, query: CareGapAuditQuery) -> [CareGapAudit] {
        return query.apply(store.list())
    }
}
