import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal targets by code.
    protocol GoalTargetStore {
        func find(_ code: String) -> GoalTarget?
        func save(_ item: GoalTarget)
        func remove(_ code: String) -> Bool
        func list() -> [GoalTarget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalTargetStore: GoalTargetStore {
        var items: [String: GoalTarget]
        var order: [String]

        init(items: [String: GoalTarget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalTarget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalTarget) {
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

        func list() -> [GoalTarget] {
            var out: [GoalTarget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalTargetStore() -> any GoalTargetStore {
        return MemoryGoalTargetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalTargetStore: GoalTargetStore {
        var inner: MemoryGoalTargetStore
        var cache: TTLCache<GoalTarget>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalTargetStore, cache: TTLCache<GoalTarget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalTarget? {
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

        func save(_ item: GoalTarget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalTarget] {
            return inner.list()
        }
    }

    static func newCachedGoalTargetStore(_ inner: MemoryGoalTargetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalTargetStore {
        return CachedGoalTargetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal targets. Empty fields match all.
    final class GoalTargetQuery {
        var unit: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalTarget) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalTarget]) -> [GoalTarget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalTarget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalTargets(_ store: any GoalTargetStore, query: GoalTargetQuery) -> [GoalTarget] {
        return query.apply(store.list())
    }
}
