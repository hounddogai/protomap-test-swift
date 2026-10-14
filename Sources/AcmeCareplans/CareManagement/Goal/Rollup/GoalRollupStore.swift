import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal rollups by code.
    protocol GoalRollupStore {
        func find(_ code: String) -> GoalRollup?
        func save(_ item: GoalRollup)
        func remove(_ code: String) -> Bool
        func list() -> [GoalRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalRollupStore: GoalRollupStore {
        var items: [String: GoalRollup]
        var order: [String]

        init(items: [String: GoalRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalRollup) {
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

        func list() -> [GoalRollup] {
            var out: [GoalRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalRollupStore() -> any GoalRollupStore {
        return MemoryGoalRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalRollupStore: GoalRollupStore {
        var inner: MemoryGoalRollupStore
        var cache: TTLCache<GoalRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalRollupStore, cache: TTLCache<GoalRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalRollup? {
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

        func save(_ item: GoalRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalRollup] {
            return inner.list()
        }
    }

    static func newCachedGoalRollupStore(_ inner: MemoryGoalRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalRollupStore {
        return CachedGoalRollupStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal rollups. Empty fields match all.
    final class GoalRollupQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalRollup) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalRollup]) -> [GoalRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalRollups(_ store: any GoalRollupStore, query: GoalRollupQuery) -> [GoalRollup] {
        return query.apply(store.list())
    }
}
