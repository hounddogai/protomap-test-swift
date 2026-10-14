import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps primary bed board plans by code.
    protocol PrimaryBedBoardPlanStore {
        func find(_ code: String) -> PrimaryBedBoardPlan?
        func save(_ item: PrimaryBedBoardPlan)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryBedBoardPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryBedBoardPlanStore: PrimaryBedBoardPlanStore {
        var items: [String: PrimaryBedBoardPlan]
        var order: [String]

        init(items: [String: PrimaryBedBoardPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryBedBoardPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryBedBoardPlan) {
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

        func list() -> [PrimaryBedBoardPlan] {
            var out: [PrimaryBedBoardPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryBedBoardPlanStore() -> any PrimaryBedBoardPlanStore {
        return MemoryPrimaryBedBoardPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryBedBoardPlanStore: PrimaryBedBoardPlanStore {
        var inner: MemoryPrimaryBedBoardPlanStore
        var cache: TTLCache<PrimaryBedBoardPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryBedBoardPlanStore, cache: TTLCache<PrimaryBedBoardPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryBedBoardPlan? {
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

        func save(_ item: PrimaryBedBoardPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryBedBoardPlan] {
            return inner.list()
        }
    }

    static func newCachedPrimaryBedBoardPlanStore(_ inner: MemoryPrimaryBedBoardPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryBedBoardPlanStore {
        return CachedPrimaryBedBoardPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary bed board plans. Empty fields match all.
    final class PrimaryBedBoardPlanQuery {
        var unit: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRefills: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryBedBoardPlan) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryBedBoardPlan]) -> [PrimaryBedBoardPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryBedBoardPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryBedBoardPlans(_ store: any PrimaryBedBoardPlanStore, query: PrimaryBedBoardPlanQuery) -> [PrimaryBedBoardPlan] {
        return query.apply(store.list())
    }
}
