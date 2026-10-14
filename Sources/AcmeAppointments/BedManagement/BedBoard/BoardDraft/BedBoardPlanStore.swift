import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board plans by code.
    protocol BedBoardPlanStore {
        func find(_ code: String) -> BedBoardPlan?
        func save(_ item: BedBoardPlan)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardPlanStore: BedBoardPlanStore {
        var items: [String: BedBoardPlan]
        var order: [String]

        init(items: [String: BedBoardPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardPlan) {
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

        func list() -> [BedBoardPlan] {
            var out: [BedBoardPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardPlanStore() -> any BedBoardPlanStore {
        return MemoryBedBoardPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardPlanStore: BedBoardPlanStore {
        var inner: MemoryBedBoardPlanStore
        var cache: TTLCache<BedBoardPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardPlanStore, cache: TTLCache<BedBoardPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardPlan? {
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

        func save(_ item: BedBoardPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardPlan] {
            return inner.list()
        }
    }

    static func newCachedBedBoardPlanStore(_ inner: MemoryBedBoardPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardPlanStore {
        return CachedBedBoardPlanStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board plans. Empty fields match all.
    final class BedBoardPlanQuery {
        var unit: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardPlan) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [BedBoardPlan]) -> [BedBoardPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardPlans(_ store: any BedBoardPlanStore, query: BedBoardPlanQuery) -> [BedBoardPlan] {
        return query.apply(store.list())
    }
}
