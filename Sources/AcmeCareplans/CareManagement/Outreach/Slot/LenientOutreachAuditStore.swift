import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps lenient outreach audits by code.
    protocol LenientOutreachAuditStore {
        func find(_ code: String) -> LenientOutreachAudit?
        func save(_ item: LenientOutreachAudit)
        func remove(_ code: String) -> Bool
        func list() -> [LenientOutreachAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientOutreachAuditStore: LenientOutreachAuditStore {
        var items: [String: LenientOutreachAudit]
        var order: [String]

        init(items: [String: LenientOutreachAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientOutreachAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientOutreachAudit) {
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

        func list() -> [LenientOutreachAudit] {
            var out: [LenientOutreachAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientOutreachAuditStore() -> any LenientOutreachAuditStore {
        return MemoryLenientOutreachAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientOutreachAuditStore: LenientOutreachAuditStore {
        var inner: MemoryLenientOutreachAuditStore
        var cache: TTLCache<LenientOutreachAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientOutreachAuditStore, cache: TTLCache<LenientOutreachAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientOutreachAudit? {
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

        func save(_ item: LenientOutreachAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientOutreachAudit] {
            return inner.list()
        }
    }

    static func newCachedLenientOutreachAuditStore(_ inner: MemoryLenientOutreachAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientOutreachAuditStore {
        return CachedLenientOutreachAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient outreach audits. Empty fields match all.
    final class LenientOutreachAuditQuery {
        var ward: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientOutreachAudit) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [LenientOutreachAudit]) -> [LenientOutreachAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientOutreachAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientOutreachAudits(_ store: any LenientOutreachAuditStore, query: LenientOutreachAuditQuery) -> [LenientOutreachAudit] {
        return query.apply(store.list())
    }
}
