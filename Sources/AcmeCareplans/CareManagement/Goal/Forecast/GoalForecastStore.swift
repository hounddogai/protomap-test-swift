import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal forecasts by code.
    protocol GoalForecastStore {
        func find(_ code: String) -> GoalForecast?
        func save(_ item: GoalForecast)
        func remove(_ code: String) -> Bool
        func list() -> [GoalForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalForecastStore: GoalForecastStore {
        var items: [String: GoalForecast]
        var order: [String]

        init(items: [String: GoalForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalForecast) {
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

        func list() -> [GoalForecast] {
            var out: [GoalForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalForecastStore() -> any GoalForecastStore {
        return MemoryGoalForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalForecastStore: GoalForecastStore {
        var inner: MemoryGoalForecastStore
        var cache: TTLCache<GoalForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalForecastStore, cache: TTLCache<GoalForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalForecast? {
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

        func save(_ item: GoalForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalForecast] {
            return inner.list()
        }
    }

    static func newCachedGoalForecastStore(_ inner: MemoryGoalForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalForecastStore {
        return CachedGoalForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal forecasts. Empty fields match all.
    final class GoalForecastQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalForecast) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalForecast]) -> [GoalForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalForecasts(_ store: any GoalForecastStore, query: GoalForecastQuery) -> [GoalForecast] {
        return query.apply(store.list())
    }
}
