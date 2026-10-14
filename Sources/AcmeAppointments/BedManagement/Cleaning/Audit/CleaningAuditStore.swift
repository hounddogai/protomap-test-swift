import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning audits by code.
    protocol CleaningAuditStore {
        func find(_ code: String) -> CleaningAudit?
        func save(_ item: CleaningAudit)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningAuditStore: CleaningAuditStore {
        var items: [String: CleaningAudit]
        var order: [String]

        init(items: [String: CleaningAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningAudit) {
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

        func list() -> [CleaningAudit] {
            var out: [CleaningAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningAuditStore() -> any CleaningAuditStore {
        return MemoryCleaningAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningAuditStore: CleaningAuditStore {
        var inner: MemoryCleaningAuditStore
        var cache: TTLCache<CleaningAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningAuditStore, cache: TTLCache<CleaningAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningAudit? {
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

        func save(_ item: CleaningAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningAudit] {
            return inner.list()
        }
    }

    static func newCachedCleaningAuditStore(_ inner: MemoryCleaningAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningAuditStore {
        return CachedCleaningAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning audits. Empty fields match all.
    final class CleaningAuditQuery {
        var country: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningAudit) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningAudit]) -> [CleaningAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningAudits(_ store: any CleaningAuditStore, query: CleaningAuditQuery) -> [CleaningAudit] {
        return query.apply(store.list())
    }
}
