import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority audits by code.
    protocol PriorityAuditStore {
        func find(_ code: String) -> PriorityAudit?
        func save(_ item: PriorityAudit)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityAuditStore: PriorityAuditStore {
        var items: [String: PriorityAudit]
        var order: [String]

        init(items: [String: PriorityAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityAudit) {
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

        func list() -> [PriorityAudit] {
            var out: [PriorityAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityAuditStore() -> any PriorityAuditStore {
        return MemoryPriorityAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityAuditStore: PriorityAuditStore {
        var inner: MemoryPriorityAuditStore
        var cache: TTLCache<PriorityAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityAuditStore, cache: TTLCache<PriorityAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityAudit? {
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

        func save(_ item: PriorityAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityAudit] {
            return inner.list()
        }
    }

    static func newCachedPriorityAuditStore(_ inner: MemoryPriorityAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityAuditStore {
        return CachedPriorityAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority audits. Empty fields match all.
    final class PriorityAuditQuery {
        var facility: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRefills: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityAudit) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PriorityAudit]) -> [PriorityAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityAudits(_ store: any PriorityAuditStore, query: PriorityAuditQuery) -> [PriorityAudit] {
        return query.apply(store.list())
    }
}
