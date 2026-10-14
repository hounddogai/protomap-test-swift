import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps fallback inventory forecasts by code.
    protocol FallbackInventoryForecastStore {
        func find(_ code: String) -> FallbackInventoryForecast?
        func save(_ item: FallbackInventoryForecast)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackInventoryForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackInventoryForecastStore: FallbackInventoryForecastStore {
        var items: [String: FallbackInventoryForecast]
        var order: [String]

        init(items: [String: FallbackInventoryForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackInventoryForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackInventoryForecast) {
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

        func list() -> [FallbackInventoryForecast] {
            var out: [FallbackInventoryForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackInventoryForecastStore() -> any FallbackInventoryForecastStore {
        return MemoryFallbackInventoryForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackInventoryForecastStore: FallbackInventoryForecastStore {
        var inner: MemoryFallbackInventoryForecastStore
        var cache: TTLCache<FallbackInventoryForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackInventoryForecastStore, cache: TTLCache<FallbackInventoryForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackInventoryForecast? {
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

        func save(_ item: FallbackInventoryForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackInventoryForecast] {
            return inner.list()
        }
    }

    static func newCachedFallbackInventoryForecastStore(_ inner: MemoryFallbackInventoryForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackInventoryForecastStore {
        return CachedFallbackInventoryForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback inventory forecasts. Empty fields match all.
    final class FallbackInventoryForecastQuery {
        var region: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minCost: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackInventoryForecast) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackInventoryForecast]) -> [FallbackInventoryForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackInventoryForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackInventoryForecasts(_ store: any FallbackInventoryForecastStore, query: FallbackInventoryForecastQuery) -> [FallbackInventoryForecast] {
        return query.apply(store.list())
    }
}
