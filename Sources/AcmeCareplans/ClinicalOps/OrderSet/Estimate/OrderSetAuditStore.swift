import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set audits by code.
    protocol OrderSetAuditStore {
        func find(_ code: String) -> OrderSetAudit?
        func save(_ item: OrderSetAudit)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetAuditStore: OrderSetAuditStore {
        var items: [String: OrderSetAudit]
        var order: [String]

        init(items: [String: OrderSetAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetAudit) {
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

        func list() -> [OrderSetAudit] {
            var out: [OrderSetAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetAuditStore() -> any OrderSetAuditStore {
        return MemoryOrderSetAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetAuditStore: OrderSetAuditStore {
        var inner: MemoryOrderSetAuditStore
        var cache: TTLCache<OrderSetAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetAuditStore, cache: TTLCache<OrderSetAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetAudit? {
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

        func save(_ item: OrderSetAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetAudit] {
            return inner.list()
        }
    }

    static func newCachedOrderSetAuditStore(_ inner: MemoryOrderSetAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetAuditStore {
        return CachedOrderSetAuditStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set audits. Empty fields match all.
    final class OrderSetAuditQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetAudit) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetAudit]) -> [OrderSetAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetAudits(_ store: any OrderSetAuditStore, query: OrderSetAuditQuery) -> [OrderSetAudit] {
        return query.apply(store.list())
    }
}
