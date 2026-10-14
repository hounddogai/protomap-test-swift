import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps global cleaning plans by code.
    protocol GlobalCleaningPlanStore {
        func find(_ code: String) -> GlobalCleaningPlan?
        func save(_ item: GlobalCleaningPlan)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalCleaningPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalCleaningPlanStore: GlobalCleaningPlanStore {
        var items: [String: GlobalCleaningPlan]
        var order: [String]

        init(items: [String: GlobalCleaningPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalCleaningPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalCleaningPlan) {
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

        func list() -> [GlobalCleaningPlan] {
            var out: [GlobalCleaningPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalCleaningPlanStore() -> any GlobalCleaningPlanStore {
        return MemoryGlobalCleaningPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalCleaningPlanStore: GlobalCleaningPlanStore {
        var inner: MemoryGlobalCleaningPlanStore
        var cache: TTLCache<GlobalCleaningPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalCleaningPlanStore, cache: TTLCache<GlobalCleaningPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalCleaningPlan? {
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

        func save(_ item: GlobalCleaningPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalCleaningPlan] {
            return inner.list()
        }
    }

    static func newCachedGlobalCleaningPlanStore(_ inner: MemoryGlobalCleaningPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalCleaningPlanStore {
        return CachedGlobalCleaningPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global cleaning plans. Empty fields match all.
    final class GlobalCleaningPlanQuery {
        var channel: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalCleaningPlan) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalCleaningPlan]) -> [GlobalCleaningPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalCleaningPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalCleaningPlans(_ store: any GlobalCleaningPlanStore, query: GlobalCleaningPlanQuery) -> [GlobalCleaningPlan] {
        return query.apply(store.list())
    }
}
