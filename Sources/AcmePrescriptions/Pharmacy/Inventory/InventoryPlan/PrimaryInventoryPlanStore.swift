import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps primary inventory plans by code.
    protocol PrimaryInventoryPlanStore {
        func find(_ code: String) -> PrimaryInventoryPlan?
        func save(_ item: PrimaryInventoryPlan)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryInventoryPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryInventoryPlanStore: PrimaryInventoryPlanStore {
        var items: [String: PrimaryInventoryPlan]
        var order: [String]

        init(items: [String: PrimaryInventoryPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryInventoryPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryInventoryPlan) {
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

        func list() -> [PrimaryInventoryPlan] {
            var out: [PrimaryInventoryPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryInventoryPlanStore() -> any PrimaryInventoryPlanStore {
        return MemoryPrimaryInventoryPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryInventoryPlanStore: PrimaryInventoryPlanStore {
        var inner: MemoryPrimaryInventoryPlanStore
        var cache: TTLCache<PrimaryInventoryPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryInventoryPlanStore, cache: TTLCache<PrimaryInventoryPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryInventoryPlan? {
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

        func save(_ item: PrimaryInventoryPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryInventoryPlan] {
            return inner.list()
        }
    }

    static func newCachedPrimaryInventoryPlanStore(_ inner: MemoryPrimaryInventoryPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryInventoryPlanStore {
        return CachedPrimaryInventoryPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary inventory plans. Empty fields match all.
    final class PrimaryInventoryPlanQuery {
        var unit: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minVersion: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryInventoryPlan) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryInventoryPlan]) -> [PrimaryInventoryPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryInventoryPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryInventoryPlans(_ store: any PrimaryInventoryPlanStore, query: PrimaryInventoryPlanQuery) -> [PrimaryInventoryPlan] {
        return query.apply(store.list())
    }
}
