import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps fallback outreach audits by code.
    protocol FallbackOutreachAuditStore {
        func find(_ code: String) -> FallbackOutreachAudit?
        func save(_ item: FallbackOutreachAudit)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackOutreachAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackOutreachAuditStore: FallbackOutreachAuditStore {
        var items: [String: FallbackOutreachAudit]
        var order: [String]

        init(items: [String: FallbackOutreachAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackOutreachAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackOutreachAudit) {
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

        func list() -> [FallbackOutreachAudit] {
            var out: [FallbackOutreachAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackOutreachAuditStore() -> any FallbackOutreachAuditStore {
        return MemoryFallbackOutreachAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackOutreachAuditStore: FallbackOutreachAuditStore {
        var inner: MemoryFallbackOutreachAuditStore
        var cache: TTLCache<FallbackOutreachAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackOutreachAuditStore, cache: TTLCache<FallbackOutreachAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackOutreachAudit? {
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

        func save(_ item: FallbackOutreachAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackOutreachAudit] {
            return inner.list()
        }
    }

    static func newCachedFallbackOutreachAuditStore(_ inner: MemoryFallbackOutreachAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackOutreachAuditStore {
        return CachedFallbackOutreachAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback outreach audits. Empty fields match all.
    final class FallbackOutreachAuditQuery {
        var facility: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackOutreachAudit) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackOutreachAudit]) -> [FallbackOutreachAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackOutreachAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackOutreachAudits(_ store: any FallbackOutreachAuditStore, query: FallbackOutreachAuditQuery) -> [FallbackOutreachAudit] {
        return query.apply(store.list())
    }
}
