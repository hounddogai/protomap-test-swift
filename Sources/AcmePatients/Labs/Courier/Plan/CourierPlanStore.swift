import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier plans by code.
    protocol CourierPlanStore {
        func find(_ code: String) -> CourierPlan?
        func save(_ item: CourierPlan)
        func remove(_ code: String) -> Bool
        func list() -> [CourierPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierPlanStore: CourierPlanStore {
        var items: [String: CourierPlan]
        var order: [String]

        init(items: [String: CourierPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierPlan) {
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

        func list() -> [CourierPlan] {
            var out: [CourierPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierPlanStore() -> any CourierPlanStore {
        return MemoryCourierPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierPlanStore: CourierPlanStore {
        var inner: MemoryCourierPlanStore
        var cache: TTLCache<CourierPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierPlanStore, cache: TTLCache<CourierPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierPlan? {
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

        func save(_ item: CourierPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierPlan] {
            return inner.list()
        }
    }

    static func newCachedCourierPlanStore(_ inner: MemoryCourierPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierPlanStore {
        return CachedCourierPlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier plans. Empty fields match all.
    final class CourierPlanQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierPlan) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [CourierPlan]) -> [CourierPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierPlans(_ store: any CourierPlanStore, query: CourierPlanQuery) -> [CourierPlan] {
        return query.apply(store.list())
    }
}
