import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps scheduled acuity plan allocations by code.
    protocol ScheduledAcuityPlanAllocationStore {
        func find(_ code: String) -> ScheduledAcuityPlanAllocation?
        func save(_ item: ScheduledAcuityPlanAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledAcuityPlanAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledAcuityPlanAllocationStore: ScheduledAcuityPlanAllocationStore {
        var items: [String: ScheduledAcuityPlanAllocation]
        var order: [String]

        init(items: [String: ScheduledAcuityPlanAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledAcuityPlanAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledAcuityPlanAllocation) {
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

        func list() -> [ScheduledAcuityPlanAllocation] {
            var out: [ScheduledAcuityPlanAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledAcuityPlanAllocationStore() -> any ScheduledAcuityPlanAllocationStore {
        return MemoryScheduledAcuityPlanAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledAcuityPlanAllocationStore: ScheduledAcuityPlanAllocationStore {
        var inner: MemoryScheduledAcuityPlanAllocationStore
        var cache: TTLCache<ScheduledAcuityPlanAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledAcuityPlanAllocationStore, cache: TTLCache<ScheduledAcuityPlanAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledAcuityPlanAllocation? {
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

        func save(_ item: ScheduledAcuityPlanAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledAcuityPlanAllocation] {
            return inner.list()
        }
    }

    static func newCachedScheduledAcuityPlanAllocationStore(_ inner: MemoryScheduledAcuityPlanAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledAcuityPlanAllocationStore {
        return CachedScheduledAcuityPlanAllocationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled acuity plan allocations. Empty fields match all.
    final class ScheduledAcuityPlanAllocationQuery {
        var label: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledAcuityPlanAllocation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledAcuityPlanAllocation]) -> [ScheduledAcuityPlanAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledAcuityPlanAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledAcuityPlanAllocations(_ store: any ScheduledAcuityPlanAllocationStore, query: ScheduledAcuityPlanAllocationQuery) -> [ScheduledAcuityPlanAllocation] {
        return query.apply(store.list())
    }
}
