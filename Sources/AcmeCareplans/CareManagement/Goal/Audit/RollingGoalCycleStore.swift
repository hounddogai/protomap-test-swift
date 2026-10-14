import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps rolling goal cycles by code.
    protocol RollingGoalCycleStore {
        func find(_ code: String) -> RollingGoalCycle?
        func save(_ item: RollingGoalCycle)
        func remove(_ code: String) -> Bool
        func list() -> [RollingGoalCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingGoalCycleStore: RollingGoalCycleStore {
        var items: [String: RollingGoalCycle]
        var order: [String]

        init(items: [String: RollingGoalCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingGoalCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingGoalCycle) {
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

        func list() -> [RollingGoalCycle] {
            var out: [RollingGoalCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingGoalCycleStore() -> any RollingGoalCycleStore {
        return MemoryRollingGoalCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingGoalCycleStore: RollingGoalCycleStore {
        var inner: MemoryRollingGoalCycleStore
        var cache: TTLCache<RollingGoalCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingGoalCycleStore, cache: TTLCache<RollingGoalCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingGoalCycle? {
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

        func save(_ item: RollingGoalCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingGoalCycle] {
            return inner.list()
        }
    }

    static func newCachedRollingGoalCycleStore(_ inner: MemoryRollingGoalCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingGoalCycleStore {
        return CachedRollingGoalCycleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling goal cycles. Empty fields match all.
    final class RollingGoalCycleQuery {
        var ward: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minAmount: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingGoalCycle) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingGoalCycle]) -> [RollingGoalCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingGoalCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingGoalCycles(_ store: any RollingGoalCycleStore, query: RollingGoalCycleQuery) -> [RollingGoalCycle] {
        return query.apply(store.list())
    }
}
