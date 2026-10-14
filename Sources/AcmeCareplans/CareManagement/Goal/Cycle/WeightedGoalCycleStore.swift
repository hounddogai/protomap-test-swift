import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted goal cycles by code.
    protocol WeightedGoalCycleStore {
        func find(_ code: String) -> WeightedGoalCycle?
        func save(_ item: WeightedGoalCycle)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedGoalCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedGoalCycleStore: WeightedGoalCycleStore {
        var items: [String: WeightedGoalCycle]
        var order: [String]

        init(items: [String: WeightedGoalCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedGoalCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedGoalCycle) {
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

        func list() -> [WeightedGoalCycle] {
            var out: [WeightedGoalCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedGoalCycleStore() -> any WeightedGoalCycleStore {
        return MemoryWeightedGoalCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedGoalCycleStore: WeightedGoalCycleStore {
        var inner: MemoryWeightedGoalCycleStore
        var cache: TTLCache<WeightedGoalCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedGoalCycleStore, cache: TTLCache<WeightedGoalCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedGoalCycle? {
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

        func save(_ item: WeightedGoalCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedGoalCycle] {
            return inner.list()
        }
    }

    static func newCachedWeightedGoalCycleStore(_ inner: MemoryWeightedGoalCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedGoalCycleStore {
        return CachedWeightedGoalCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted goal cycles. Empty fields match all.
    final class WeightedGoalCycleQuery {
        var facility: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedGoalCycle) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedGoalCycle]) -> [WeightedGoalCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedGoalCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedGoalCycles(_ store: any WeightedGoalCycleStore, query: WeightedGoalCycleQuery) -> [WeightedGoalCycle] {
        return query.apply(store.list())
    }
}
