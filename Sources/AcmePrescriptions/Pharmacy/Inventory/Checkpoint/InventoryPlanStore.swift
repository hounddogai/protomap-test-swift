import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory plans by code.
    protocol InventoryPlanStore {
        func find(_ code: String) -> InventoryPlan?
        func save(_ item: InventoryPlan)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryPlanStore: InventoryPlanStore {
        var items: [String: InventoryPlan]
        var order: [String]

        init(items: [String: InventoryPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryPlan) {
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

        func list() -> [InventoryPlan] {
            var out: [InventoryPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryPlanStore() -> any InventoryPlanStore {
        return MemoryInventoryPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryPlanStore: InventoryPlanStore {
        var inner: MemoryInventoryPlanStore
        var cache: TTLCache<InventoryPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryPlanStore, cache: TTLCache<InventoryPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryPlan? {
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

        func save(_ item: InventoryPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryPlan] {
            return inner.list()
        }
    }

    static func newCachedInventoryPlanStore(_ inner: MemoryInventoryPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryPlanStore {
        return CachedInventoryPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory plans. Empty fields match all.
    final class InventoryPlanQuery {
        var segment: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryPlan) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryPlan]) -> [InventoryPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryPlans(_ store: any InventoryPlanStore, query: InventoryPlanQuery) -> [InventoryPlan] {
        return query.apply(store.list())
    }
}
