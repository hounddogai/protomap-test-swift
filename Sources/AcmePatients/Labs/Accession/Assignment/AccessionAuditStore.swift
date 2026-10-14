import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession audits by code.
    protocol AccessionAuditStore {
        func find(_ code: String) -> AccessionAudit?
        func save(_ item: AccessionAudit)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionAuditStore: AccessionAuditStore {
        var items: [String: AccessionAudit]
        var order: [String]

        init(items: [String: AccessionAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionAudit) {
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

        func list() -> [AccessionAudit] {
            var out: [AccessionAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionAuditStore() -> any AccessionAuditStore {
        return MemoryAccessionAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionAuditStore: AccessionAuditStore {
        var inner: MemoryAccessionAuditStore
        var cache: TTLCache<AccessionAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionAuditStore, cache: TTLCache<AccessionAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionAudit? {
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

        func save(_ item: AccessionAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionAudit] {
            return inner.list()
        }
    }

    static func newCachedAccessionAuditStore(_ inner: MemoryAccessionAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionAuditStore {
        return CachedAccessionAuditStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession audits. Empty fields match all.
    final class AccessionAuditQuery {
        var ward: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionAudit) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [AccessionAudit]) -> [AccessionAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionAudits(_ store: any AccessionAuditStore, query: AccessionAuditQuery) -> [AccessionAudit] {
        return query.apply(store.list())
    }
}
