import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen plans by code.
    protocol SpecimenPlanStore {
        func find(_ code: String) -> SpecimenPlan?
        func save(_ item: SpecimenPlan)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenPlanStore: SpecimenPlanStore {
        var items: [String: SpecimenPlan]
        var order: [String]

        init(items: [String: SpecimenPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenPlan) {
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

        func list() -> [SpecimenPlan] {
            var out: [SpecimenPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenPlanStore() -> any SpecimenPlanStore {
        return MemorySpecimenPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenPlanStore: SpecimenPlanStore {
        var inner: MemorySpecimenPlanStore
        var cache: TTLCache<SpecimenPlan>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenPlanStore, cache: TTLCache<SpecimenPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenPlan? {
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

        func save(_ item: SpecimenPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenPlan] {
            return inner.list()
        }
    }

    static func newCachedSpecimenPlanStore(_ inner: MemorySpecimenPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenPlanStore {
        return CachedSpecimenPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen plans. Empty fields match all.
    final class SpecimenPlanQuery {
        var unit: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenPlan) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [SpecimenPlan]) -> [SpecimenPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenPlans(_ store: any SpecimenPlanStore, query: SpecimenPlanQuery) -> [SpecimenPlan] {
        return query.apply(store.list())
    }
}
