import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness forecasts by code.
    protocol WitnessForecastStore {
        func find(_ code: String) -> WitnessForecast?
        func save(_ item: WitnessForecast)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessForecastStore: WitnessForecastStore {
        var items: [String: WitnessForecast]
        var order: [String]

        init(items: [String: WitnessForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessForecast) {
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

        func list() -> [WitnessForecast] {
            var out: [WitnessForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessForecastStore() -> any WitnessForecastStore {
        return MemoryWitnessForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessForecastStore: WitnessForecastStore {
        var inner: MemoryWitnessForecastStore
        var cache: TTLCache<WitnessForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessForecastStore, cache: TTLCache<WitnessForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessForecast? {
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

        func save(_ item: WitnessForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessForecast] {
            return inner.list()
        }
    }

    static func newCachedWitnessForecastStore(_ inner: MemoryWitnessForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessForecastStore {
        return CachedWitnessForecastStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness forecasts. Empty fields match all.
    final class WitnessForecastQuery {
        var country: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessForecast) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessForecast]) -> [WitnessForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessForecasts(_ store: any WitnessForecastStore, query: WitnessForecastQuery) -> [WitnessForecast] {
        return query.apply(store.list())
    }
}
