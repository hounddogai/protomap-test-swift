import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal variances by code.
    protocol GoalVarianceStore {
        func find(_ code: String) -> GoalVariance?
        func save(_ item: GoalVariance)
        func remove(_ code: String) -> Bool
        func list() -> [GoalVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalVarianceStore: GoalVarianceStore {
        var items: [String: GoalVariance]
        var order: [String]

        init(items: [String: GoalVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalVariance) {
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

        func list() -> [GoalVariance] {
            var out: [GoalVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalVarianceStore() -> any GoalVarianceStore {
        return MemoryGoalVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalVarianceStore: GoalVarianceStore {
        var inner: MemoryGoalVarianceStore
        var cache: TTLCache<GoalVariance>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalVarianceStore, cache: TTLCache<GoalVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalVariance? {
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

        func save(_ item: GoalVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalVariance] {
            return inner.list()
        }
    }

    static func newCachedGoalVarianceStore(_ inner: MemoryGoalVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalVarianceStore {
        return CachedGoalVarianceStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal variances. Empty fields match all.
    final class GoalVarianceQuery {
        var channel: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalVariance) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalVariance]) -> [GoalVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalVariances(_ store: any GoalVarianceStore, query: GoalVarianceQuery) -> [GoalVariance] {
        return query.apply(store.list())
    }
}
