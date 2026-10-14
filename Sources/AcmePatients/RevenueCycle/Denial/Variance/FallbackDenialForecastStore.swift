import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback denial forecasts by code.
    protocol FallbackDenialForecastStore {
        func find(_ code: String) -> FallbackDenialForecast?
        func save(_ item: FallbackDenialForecast)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDenialForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDenialForecastStore: FallbackDenialForecastStore {
        var items: [String: FallbackDenialForecast]
        var order: [String]

        init(items: [String: FallbackDenialForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDenialForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDenialForecast) {
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

        func list() -> [FallbackDenialForecast] {
            var out: [FallbackDenialForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDenialForecastStore() -> any FallbackDenialForecastStore {
        return MemoryFallbackDenialForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDenialForecastStore: FallbackDenialForecastStore {
        var inner: MemoryFallbackDenialForecastStore
        var cache: TTLCache<FallbackDenialForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDenialForecastStore, cache: TTLCache<FallbackDenialForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDenialForecast? {
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

        func save(_ item: FallbackDenialForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDenialForecast] {
            return inner.list()
        }
    }

    static func newCachedFallbackDenialForecastStore(_ inner: MemoryFallbackDenialForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDenialForecastStore {
        return CachedFallbackDenialForecastStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback denial forecasts. Empty fields match all.
    final class FallbackDenialForecastQuery {
        var region: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minRatio: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDenialForecast) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackDenialForecast]) -> [FallbackDenialForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDenialForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDenialForecasts(_ store: any FallbackDenialForecastStore, query: FallbackDenialForecastQuery) -> [FallbackDenialForecast] {
        return query.apply(store.list())
    }
}
