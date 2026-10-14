import AcmePlatform
import Foundation

extension Labs {
    /// Keeps default specimen plans by code.
    protocol DefaultSpecimenPlanStore {
        func find(_ code: String) -> DefaultSpecimenPlan?
        func save(_ item: DefaultSpecimenPlan)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultSpecimenPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultSpecimenPlanStore: DefaultSpecimenPlanStore {
        var items: [String: DefaultSpecimenPlan]
        var order: [String]

        init(items: [String: DefaultSpecimenPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultSpecimenPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultSpecimenPlan) {
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

        func list() -> [DefaultSpecimenPlan] {
            var out: [DefaultSpecimenPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultSpecimenPlanStore() -> any DefaultSpecimenPlanStore {
        return MemoryDefaultSpecimenPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultSpecimenPlanStore: DefaultSpecimenPlanStore {
        var inner: MemoryDefaultSpecimenPlanStore
        var cache: TTLCache<DefaultSpecimenPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultSpecimenPlanStore, cache: TTLCache<DefaultSpecimenPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultSpecimenPlan? {
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

        func save(_ item: DefaultSpecimenPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultSpecimenPlan] {
            return inner.list()
        }
    }

    static func newCachedDefaultSpecimenPlanStore(_ inner: MemoryDefaultSpecimenPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultSpecimenPlanStore {
        return CachedDefaultSpecimenPlanStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default specimen plans. Empty fields match all.
    final class DefaultSpecimenPlanQuery {
        var unit: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultSpecimenPlan) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [DefaultSpecimenPlan]) -> [DefaultSpecimenPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultSpecimenPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultSpecimenPlans(_ store: any DefaultSpecimenPlanStore, query: DefaultSpecimenPlanQuery) -> [DefaultSpecimenPlan] {
        return query.apply(store.list())
    }
}
