import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps adaptive risk score forecasts by code.
    protocol AdaptiveRiskScoreForecastStore {
        func find(_ code: String) -> AdaptiveRiskScoreForecast?
        func save(_ item: AdaptiveRiskScoreForecast)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveRiskScoreForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveRiskScoreForecastStore: AdaptiveRiskScoreForecastStore {
        var items: [String: AdaptiveRiskScoreForecast]
        var order: [String]

        init(items: [String: AdaptiveRiskScoreForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveRiskScoreForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveRiskScoreForecast) {
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

        func list() -> [AdaptiveRiskScoreForecast] {
            var out: [AdaptiveRiskScoreForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveRiskScoreForecastStore() -> any AdaptiveRiskScoreForecastStore {
        return MemoryAdaptiveRiskScoreForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveRiskScoreForecastStore: AdaptiveRiskScoreForecastStore {
        var inner: MemoryAdaptiveRiskScoreForecastStore
        var cache: TTLCache<AdaptiveRiskScoreForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveRiskScoreForecastStore, cache: TTLCache<AdaptiveRiskScoreForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveRiskScoreForecast? {
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

        func save(_ item: AdaptiveRiskScoreForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveRiskScoreForecast] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveRiskScoreForecastStore(_ inner: MemoryAdaptiveRiskScoreForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveRiskScoreForecastStore {
        return CachedAdaptiveRiskScoreForecastStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive risk score forecasts. Empty fields match all.
    final class AdaptiveRiskScoreForecastQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveRiskScoreForecast) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveRiskScoreForecast]) -> [AdaptiveRiskScoreForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveRiskScoreForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveRiskScoreForecasts(_ store: any AdaptiveRiskScoreForecastStore, query: AdaptiveRiskScoreForecastQuery) -> [AdaptiveRiskScoreForecast] {
        return query.apply(store.list())
    }
}
