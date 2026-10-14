import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive eligibility forecasts by code.
    protocol AdaptiveEligibilityForecastStore {
        func find(_ code: String) -> AdaptiveEligibilityForecast?
        func save(_ item: AdaptiveEligibilityForecast)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveEligibilityForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveEligibilityForecastStore: AdaptiveEligibilityForecastStore {
        var items: [String: AdaptiveEligibilityForecast]
        var order: [String]

        init(items: [String: AdaptiveEligibilityForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveEligibilityForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveEligibilityForecast) {
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

        func list() -> [AdaptiveEligibilityForecast] {
            var out: [AdaptiveEligibilityForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveEligibilityForecastStore() -> any AdaptiveEligibilityForecastStore {
        return MemoryAdaptiveEligibilityForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveEligibilityForecastStore: AdaptiveEligibilityForecastStore {
        var inner: MemoryAdaptiveEligibilityForecastStore
        var cache: TTLCache<AdaptiveEligibilityForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveEligibilityForecastStore, cache: TTLCache<AdaptiveEligibilityForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveEligibilityForecast? {
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

        func save(_ item: AdaptiveEligibilityForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveEligibilityForecast] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveEligibilityForecastStore(_ inner: MemoryAdaptiveEligibilityForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveEligibilityForecastStore {
        return CachedAdaptiveEligibilityForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive eligibility forecasts. Empty fields match all.
    final class AdaptiveEligibilityForecastQuery {
        var channel: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMargin: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveEligibilityForecast) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveEligibilityForecast]) -> [AdaptiveEligibilityForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveEligibilityForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveEligibilityForecasts(_ store: any AdaptiveEligibilityForecastStore, query: AdaptiveEligibilityForecastQuery) -> [AdaptiveEligibilityForecast] {
        return query.apply(store.list())
    }
}
