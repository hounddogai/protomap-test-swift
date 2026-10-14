import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps weighted inventory audits by code.
    protocol WeightedInventoryAuditStore {
        func find(_ code: String) -> WeightedInventoryAudit?
        func save(_ item: WeightedInventoryAudit)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedInventoryAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedInventoryAuditStore: WeightedInventoryAuditStore {
        var items: [String: WeightedInventoryAudit]
        var order: [String]

        init(items: [String: WeightedInventoryAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedInventoryAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedInventoryAudit) {
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

        func list() -> [WeightedInventoryAudit] {
            var out: [WeightedInventoryAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedInventoryAuditStore() -> any WeightedInventoryAuditStore {
        return MemoryWeightedInventoryAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedInventoryAuditStore: WeightedInventoryAuditStore {
        var inner: MemoryWeightedInventoryAuditStore
        var cache: TTLCache<WeightedInventoryAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedInventoryAuditStore, cache: TTLCache<WeightedInventoryAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedInventoryAudit? {
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

        func save(_ item: WeightedInventoryAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedInventoryAudit] {
            return inner.list()
        }
    }

    static func newCachedWeightedInventoryAuditStore(_ inner: MemoryWeightedInventoryAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedInventoryAuditStore {
        return CachedWeightedInventoryAuditStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted inventory audits. Empty fields match all.
    final class WeightedInventoryAuditQuery {
        var facility: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedInventoryAudit) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedInventoryAudit]) -> [WeightedInventoryAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedInventoryAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedInventoryAudits(_ store: any WeightedInventoryAuditStore, query: WeightedInventoryAuditQuery) -> [WeightedInventoryAudit] {
        return query.apply(store.list())
    }
}
