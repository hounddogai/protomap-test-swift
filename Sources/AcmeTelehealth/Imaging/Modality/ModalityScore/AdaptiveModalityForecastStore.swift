import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps adaptive modality forecasts by code.
    protocol AdaptiveModalityForecastStore {
        func find(_ code: String) -> AdaptiveModalityForecast?
        func save(_ item: AdaptiveModalityForecast)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveModalityForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveModalityForecastStore: AdaptiveModalityForecastStore {
        var items: [String: AdaptiveModalityForecast]
        var order: [String]

        init(items: [String: AdaptiveModalityForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveModalityForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveModalityForecast) {
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

        func list() -> [AdaptiveModalityForecast] {
            var out: [AdaptiveModalityForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveModalityForecastStore() -> any AdaptiveModalityForecastStore {
        return MemoryAdaptiveModalityForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveModalityForecastStore: AdaptiveModalityForecastStore {
        var inner: MemoryAdaptiveModalityForecastStore
        var cache: TTLCache<AdaptiveModalityForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveModalityForecastStore, cache: TTLCache<AdaptiveModalityForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveModalityForecast? {
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

        func save(_ item: AdaptiveModalityForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveModalityForecast] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveModalityForecastStore(_ inner: MemoryAdaptiveModalityForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveModalityForecastStore {
        return CachedAdaptiveModalityForecastStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive modality forecasts. Empty fields match all.
    final class AdaptiveModalityForecastQuery {
        var category: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveModalityForecast) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveModalityForecast]) -> [AdaptiveModalityForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveModalityForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveModalityForecasts(_ store: any AdaptiveModalityForecastStore, query: AdaptiveModalityForecastQuery) -> [AdaptiveModalityForecast] {
        return query.apply(store.list())
    }
}
