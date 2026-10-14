import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census audits by code.
    protocol CensusAuditStore {
        func find(_ code: String) -> CensusAudit?
        func save(_ item: CensusAudit)
        func remove(_ code: String) -> Bool
        func list() -> [CensusAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusAuditStore: CensusAuditStore {
        var items: [String: CensusAudit]
        var order: [String]

        init(items: [String: CensusAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusAudit) {
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

        func list() -> [CensusAudit] {
            var out: [CensusAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusAuditStore() -> any CensusAuditStore {
        return MemoryCensusAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusAuditStore: CensusAuditStore {
        var inner: MemoryCensusAuditStore
        var cache: TTLCache<CensusAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusAuditStore, cache: TTLCache<CensusAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusAudit? {
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

        func save(_ item: CensusAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusAudit] {
            return inner.list()
        }
    }

    static func newCachedCensusAuditStore(_ inner: MemoryCensusAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusAuditStore {
        return CachedCensusAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census audits. Empty fields match all.
    final class CensusAuditQuery {
        var country: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusAudit) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusAudit]) -> [CensusAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusAudits(_ store: any CensusAuditStore, query: CensusAuditQuery) -> [CensusAudit] {
        return query.apply(store.list())
    }
}
