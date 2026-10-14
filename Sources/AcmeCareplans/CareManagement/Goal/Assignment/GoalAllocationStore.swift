import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal allocations by code.
    protocol GoalAllocationStore {
        func find(_ code: String) -> GoalAllocation?
        func save(_ item: GoalAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [GoalAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalAllocationStore: GoalAllocationStore {
        var items: [String: GoalAllocation]
        var order: [String]

        init(items: [String: GoalAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalAllocation) {
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

        func list() -> [GoalAllocation] {
            var out: [GoalAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalAllocationStore() -> any GoalAllocationStore {
        return MemoryGoalAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalAllocationStore: GoalAllocationStore {
        var inner: MemoryGoalAllocationStore
        var cache: TTLCache<GoalAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalAllocationStore, cache: TTLCache<GoalAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalAllocation? {
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

        func save(_ item: GoalAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalAllocation] {
            return inner.list()
        }
    }

    static func newCachedGoalAllocationStore(_ inner: MemoryGoalAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalAllocationStore {
        return CachedGoalAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal allocations. Empty fields match all.
    final class GoalAllocationQuery {
        var country: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minVersion: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalAllocation) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [GoalAllocation]) -> [GoalAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalAllocations(_ store: any GoalAllocationStore, query: GoalAllocationQuery) -> [GoalAllocation] {
        return query.apply(store.list())
    }
}
