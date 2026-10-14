import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal checkpoints by code.
    protocol GoalCheckpointStore {
        func find(_ code: String) -> GoalCheckpoint?
        func save(_ item: GoalCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [GoalCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalCheckpointStore: GoalCheckpointStore {
        var items: [String: GoalCheckpoint]
        var order: [String]

        init(items: [String: GoalCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalCheckpoint) {
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

        func list() -> [GoalCheckpoint] {
            var out: [GoalCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalCheckpointStore() -> any GoalCheckpointStore {
        return MemoryGoalCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalCheckpointStore: GoalCheckpointStore {
        var inner: MemoryGoalCheckpointStore
        var cache: TTLCache<GoalCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalCheckpointStore, cache: TTLCache<GoalCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalCheckpoint? {
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

        func save(_ item: GoalCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedGoalCheckpointStore(_ inner: MemoryGoalCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalCheckpointStore {
        return CachedGoalCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal checkpoints. Empty fields match all.
    final class GoalCheckpointQuery {
        var channel: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalCheckpoint) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [GoalCheckpoint]) -> [GoalCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalCheckpoints(_ store: any GoalCheckpointStore, query: GoalCheckpointQuery) -> [GoalCheckpoint] {
        return query.apply(store.list())
    }
}
