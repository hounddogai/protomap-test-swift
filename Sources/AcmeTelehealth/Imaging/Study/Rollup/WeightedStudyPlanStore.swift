import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps weighted study plans by code.
    protocol WeightedStudyPlanStore {
        func find(_ code: String) -> WeightedStudyPlan?
        func save(_ item: WeightedStudyPlan)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedStudyPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedStudyPlanStore: WeightedStudyPlanStore {
        var items: [String: WeightedStudyPlan]
        var order: [String]

        init(items: [String: WeightedStudyPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedStudyPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedStudyPlan) {
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

        func list() -> [WeightedStudyPlan] {
            var out: [WeightedStudyPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedStudyPlanStore() -> any WeightedStudyPlanStore {
        return MemoryWeightedStudyPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedStudyPlanStore: WeightedStudyPlanStore {
        var inner: MemoryWeightedStudyPlanStore
        var cache: TTLCache<WeightedStudyPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedStudyPlanStore, cache: TTLCache<WeightedStudyPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedStudyPlan? {
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

        func save(_ item: WeightedStudyPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedStudyPlan] {
            return inner.list()
        }
    }

    static func newCachedWeightedStudyPlanStore(_ inner: MemoryWeightedStudyPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedStudyPlanStore {
        return CachedWeightedStudyPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted study plans. Empty fields match all.
    final class WeightedStudyPlanQuery {
        var channel: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minWeight: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedStudyPlan) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedStudyPlan]) -> [WeightedStudyPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedStudyPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedStudyPlans(_ store: any WeightedStudyPlanStore, query: WeightedStudyPlanQuery) -> [WeightedStudyPlan] {
        return query.apply(store.list())
    }
}
