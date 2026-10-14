import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps adaptive denial forecasts by code.
    protocol AdaptiveDenialForecastStore {
        func find(_ code: String) -> AdaptiveDenialForecast?
        func save(_ item: AdaptiveDenialForecast)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveDenialForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveDenialForecastStore: AdaptiveDenialForecastStore {
        var items: [String: AdaptiveDenialForecast]
        var order: [String]

        init(items: [String: AdaptiveDenialForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveDenialForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveDenialForecast) {
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

        func list() -> [AdaptiveDenialForecast] {
            var out: [AdaptiveDenialForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveDenialForecastStore() -> any AdaptiveDenialForecastStore {
        return MemoryAdaptiveDenialForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveDenialForecastStore: AdaptiveDenialForecastStore {
        var inner: MemoryAdaptiveDenialForecastStore
        var cache: TTLCache<AdaptiveDenialForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveDenialForecastStore, cache: TTLCache<AdaptiveDenialForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveDenialForecast? {
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

        func save(_ item: AdaptiveDenialForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveDenialForecast] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveDenialForecastStore(_ inner: MemoryAdaptiveDenialForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveDenialForecastStore {
        return CachedAdaptiveDenialForecastStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive denial forecasts. Empty fields match all.
    final class AdaptiveDenialForecastQuery {
        var locale: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveDenialForecast) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveDenialForecast]) -> [AdaptiveDenialForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveDenialForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveDenialForecasts(_ store: any AdaptiveDenialForecastStore, query: AdaptiveDenialForecastQuery) -> [AdaptiveDenialForecast] {
        return query.apply(store.list())
    }
}
