import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps rolling recall plans by code.
    protocol RollingRecallPlanStore {
        func find(_ code: String) -> RollingRecallPlan?
        func save(_ item: RollingRecallPlan)
        func remove(_ code: String) -> Bool
        func list() -> [RollingRecallPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingRecallPlanStore: RollingRecallPlanStore {
        var items: [String: RollingRecallPlan]
        var order: [String]

        init(items: [String: RollingRecallPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingRecallPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingRecallPlan) {
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

        func list() -> [RollingRecallPlan] {
            var out: [RollingRecallPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingRecallPlanStore() -> any RollingRecallPlanStore {
        return MemoryRollingRecallPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingRecallPlanStore: RollingRecallPlanStore {
        var inner: MemoryRollingRecallPlanStore
        var cache: TTLCache<RollingRecallPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingRecallPlanStore, cache: TTLCache<RollingRecallPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingRecallPlan? {
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

        func save(_ item: RollingRecallPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingRecallPlan] {
            return inner.list()
        }
    }

    static func newCachedRollingRecallPlanStore(_ inner: MemoryRollingRecallPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingRecallPlanStore {
        return CachedRollingRecallPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling recall plans. Empty fields match all.
    final class RollingRecallPlanQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingRecallPlan) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [RollingRecallPlan]) -> [RollingRecallPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingRecallPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingRecallPlans(_ store: any RollingRecallPlanStore, query: RollingRecallPlanQuery) -> [RollingRecallPlan] {
        return query.apply(store.list())
    }
}
