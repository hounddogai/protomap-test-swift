import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps scheduled goal checkpoints by code.
    protocol ScheduledGoalCheckpointStore {
        func find(_ code: String) -> ScheduledGoalCheckpoint?
        func save(_ item: ScheduledGoalCheckpoint)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledGoalCheckpoint]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledGoalCheckpointStore: ScheduledGoalCheckpointStore {
        var items: [String: ScheduledGoalCheckpoint]
        var order: [String]

        init(items: [String: ScheduledGoalCheckpoint], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledGoalCheckpoint? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledGoalCheckpoint) {
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

        func list() -> [ScheduledGoalCheckpoint] {
            var out: [ScheduledGoalCheckpoint] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledGoalCheckpointStore() -> any ScheduledGoalCheckpointStore {
        return MemoryScheduledGoalCheckpointStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledGoalCheckpointStore: ScheduledGoalCheckpointStore {
        var inner: MemoryScheduledGoalCheckpointStore
        var cache: TTLCache<ScheduledGoalCheckpoint>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledGoalCheckpointStore, cache: TTLCache<ScheduledGoalCheckpoint>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledGoalCheckpoint? {
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

        func save(_ item: ScheduledGoalCheckpoint) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledGoalCheckpoint] {
            return inner.list()
        }
    }

    static func newCachedScheduledGoalCheckpointStore(_ inner: MemoryScheduledGoalCheckpointStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledGoalCheckpointStore {
        return CachedScheduledGoalCheckpointStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled goal checkpoints. Empty fields match all.
    final class ScheduledGoalCheckpointQuery {
        var title: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRate: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledGoalCheckpoint) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledGoalCheckpoint]) -> [ScheduledGoalCheckpoint] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledGoalCheckpoint) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledGoalCheckpoints(_ store: any ScheduledGoalCheckpointStore, query: ScheduledGoalCheckpointQuery) -> [ScheduledGoalCheckpoint] {
        return query.apply(store.list())
    }
}
