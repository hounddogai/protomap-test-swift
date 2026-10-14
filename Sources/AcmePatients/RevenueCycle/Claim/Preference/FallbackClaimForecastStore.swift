import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback claim forecasts by code.
    protocol FallbackClaimForecastStore {
        func find(_ code: String) -> FallbackClaimForecast?
        func save(_ item: FallbackClaimForecast)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackClaimForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackClaimForecastStore: FallbackClaimForecastStore {
        var items: [String: FallbackClaimForecast]
        var order: [String]

        init(items: [String: FallbackClaimForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackClaimForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackClaimForecast) {
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

        func list() -> [FallbackClaimForecast] {
            var out: [FallbackClaimForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackClaimForecastStore() -> any FallbackClaimForecastStore {
        return MemoryFallbackClaimForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackClaimForecastStore: FallbackClaimForecastStore {
        var inner: MemoryFallbackClaimForecastStore
        var cache: TTLCache<FallbackClaimForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackClaimForecastStore, cache: TTLCache<FallbackClaimForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackClaimForecast? {
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

        func save(_ item: FallbackClaimForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackClaimForecast] {
            return inner.list()
        }
    }

    static func newCachedFallbackClaimForecastStore(_ inner: MemoryFallbackClaimForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackClaimForecastStore {
        return CachedFallbackClaimForecastStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback claim forecasts. Empty fields match all.
    final class FallbackClaimForecastQuery {
        var name: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackClaimForecast) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [FallbackClaimForecast]) -> [FallbackClaimForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackClaimForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackClaimForecasts(_ store: any FallbackClaimForecastStore, query: FallbackClaimForecastQuery) -> [FallbackClaimForecast] {
        return query.apply(store.list())
    }
}
