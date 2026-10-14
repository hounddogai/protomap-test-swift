import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal metrics by code.
    protocol GoalMetricStore {
        func find(_ code: String) -> GoalMetric?
        func save(_ item: GoalMetric)
        func remove(_ code: String) -> Bool
        func list() -> [GoalMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalMetricStore: GoalMetricStore {
        var items: [String: GoalMetric]
        var order: [String]

        init(items: [String: GoalMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalMetric) {
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

        func list() -> [GoalMetric] {
            var out: [GoalMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalMetricStore() -> any GoalMetricStore {
        return MemoryGoalMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalMetricStore: GoalMetricStore {
        var inner: MemoryGoalMetricStore
        var cache: TTLCache<GoalMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalMetricStore, cache: TTLCache<GoalMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalMetric? {
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

        func save(_ item: GoalMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalMetric] {
            return inner.list()
        }
    }

    static func newCachedGoalMetricStore(_ inner: MemoryGoalMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalMetricStore {
        return CachedGoalMetricStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal metrics. Empty fields match all.
    final class GoalMetricQuery {
        var ward: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minRetries: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalMetric) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalMetric]) -> [GoalMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalMetrics(_ store: any GoalMetricStore, query: GoalMetricQuery) -> [GoalMetric] {
        return query.apply(store.list())
    }
}
