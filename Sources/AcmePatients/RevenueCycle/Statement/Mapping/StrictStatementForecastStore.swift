import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps strict statement forecasts by code.
    protocol StrictStatementForecastStore {
        func find(_ code: String) -> StrictStatementForecast?
        func save(_ item: StrictStatementForecast)
        func remove(_ code: String) -> Bool
        func list() -> [StrictStatementForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictStatementForecastStore: StrictStatementForecastStore {
        var items: [String: StrictStatementForecast]
        var order: [String]

        init(items: [String: StrictStatementForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictStatementForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictStatementForecast) {
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

        func list() -> [StrictStatementForecast] {
            var out: [StrictStatementForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictStatementForecastStore() -> any StrictStatementForecastStore {
        return MemoryStrictStatementForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictStatementForecastStore: StrictStatementForecastStore {
        var inner: MemoryStrictStatementForecastStore
        var cache: TTLCache<StrictStatementForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictStatementForecastStore, cache: TTLCache<StrictStatementForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictStatementForecast? {
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

        func save(_ item: StrictStatementForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictStatementForecast] {
            return inner.list()
        }
    }

    static func newCachedStrictStatementForecastStore(_ inner: MemoryStrictStatementForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictStatementForecastStore {
        return CachedStrictStatementForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict statement forecasts. Empty fields match all.
    final class StrictStatementForecastQuery {
        var country: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minRate: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictStatementForecast) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [StrictStatementForecast]) -> [StrictStatementForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictStatementForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictStatementForecasts(_ store: any StrictStatementForecastStore, query: StrictStatementForecastQuery) -> [StrictStatementForecast] {
        return query.apply(store.list())
    }
}
