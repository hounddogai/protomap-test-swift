import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal plans by code.
    protocol GoalPlanStore {
        func find(_ code: String) -> GoalPlan?
        func save(_ item: GoalPlan)
        func remove(_ code: String) -> Bool
        func list() -> [GoalPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalPlanStore: GoalPlanStore {
        var items: [String: GoalPlan]
        var order: [String]

        init(items: [String: GoalPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalPlan) {
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

        func list() -> [GoalPlan] {
            var out: [GoalPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalPlanStore() -> any GoalPlanStore {
        return MemoryGoalPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalPlanStore: GoalPlanStore {
        var inner: MemoryGoalPlanStore
        var cache: TTLCache<GoalPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalPlanStore, cache: TTLCache<GoalPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalPlan? {
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

        func save(_ item: GoalPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalPlan] {
            return inner.list()
        }
    }

    static func newCachedGoalPlanStore(_ inner: MemoryGoalPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalPlanStore {
        return CachedGoalPlanStore(inner: inner, cache: newTTLCache(256, ttl: ttl, clock: clock), hits: 0, misses: 0)
    }

    /// Selects goal plans. Empty fields match all.
    final class GoalPlanQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalPlan) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [GoalPlan]) -> [GoalPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalPlans(_ store: any GoalPlanStore, query: GoalPlanQuery) -> [GoalPlan] {
        return query.apply(store.list())
    }
}
