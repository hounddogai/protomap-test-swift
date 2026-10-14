import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps seasonal denial forecasts by code.
    protocol SeasonalDenialForecastStore {
        func find(_ code: String) -> SeasonalDenialForecast?
        func save(_ item: SeasonalDenialForecast)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalDenialForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalDenialForecastStore: SeasonalDenialForecastStore {
        var items: [String: SeasonalDenialForecast]
        var order: [String]

        init(items: [String: SeasonalDenialForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalDenialForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalDenialForecast) {
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

        func list() -> [SeasonalDenialForecast] {
            var out: [SeasonalDenialForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalDenialForecastStore() -> any SeasonalDenialForecastStore {
        return MemorySeasonalDenialForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalDenialForecastStore: SeasonalDenialForecastStore {
        var inner: MemorySeasonalDenialForecastStore
        var cache: TTLCache<SeasonalDenialForecast>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalDenialForecastStore, cache: TTLCache<SeasonalDenialForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalDenialForecast? {
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

        func save(_ item: SeasonalDenialForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalDenialForecast] {
            return inner.list()
        }
    }

    static func newCachedSeasonalDenialForecastStore(_ inner: MemorySeasonalDenialForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalDenialForecastStore {
        return CachedSeasonalDenialForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal denial forecasts. Empty fields match all.
    final class SeasonalDenialForecastQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalDenialForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalDenialForecast]) -> [SeasonalDenialForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalDenialForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalDenialForecasts(_ store: any SeasonalDenialForecastStore, query: SeasonalDenialForecastQuery) -> [SeasonalDenialForecast] {
        return query.apply(store.list())
    }
}
