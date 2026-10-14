import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps adaptive inventory audits by code.
    protocol AdaptiveInventoryAuditStore {
        func find(_ code: String) -> AdaptiveInventoryAudit?
        func save(_ item: AdaptiveInventoryAudit)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveInventoryAudit]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveInventoryAuditStore: AdaptiveInventoryAuditStore {
        var items: [String: AdaptiveInventoryAudit]
        var order: [String]

        init(items: [String: AdaptiveInventoryAudit], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveInventoryAudit? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveInventoryAudit) {
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

        func list() -> [AdaptiveInventoryAudit] {
            var out: [AdaptiveInventoryAudit] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveInventoryAuditStore() -> any AdaptiveInventoryAuditStore {
        return MemoryAdaptiveInventoryAuditStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveInventoryAuditStore: AdaptiveInventoryAuditStore {
        var inner: MemoryAdaptiveInventoryAuditStore
        var cache: TTLCache<AdaptiveInventoryAudit>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveInventoryAuditStore, cache: TTLCache<AdaptiveInventoryAudit>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveInventoryAudit? {
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

        func save(_ item: AdaptiveInventoryAudit) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveInventoryAudit] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveInventoryAuditStore(_ inner: MemoryAdaptiveInventoryAuditStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveInventoryAuditStore {
        return CachedAdaptiveInventoryAuditStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive inventory audits. Empty fields match all.
    final class AdaptiveInventoryAuditQuery {
        var ward: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCost: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveInventoryAudit) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [AdaptiveInventoryAudit]) -> [AdaptiveInventoryAudit] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveInventoryAudit) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveInventoryAudits(_ store: any AdaptiveInventoryAuditStore, query: AdaptiveInventoryAuditQuery) -> [AdaptiveInventoryAudit] {
        return query.apply(store.list())
    }
}
