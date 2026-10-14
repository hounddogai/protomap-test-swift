import AcmePlatform
import Foundation

extension Consent {
    /// Keeps global disclosure forecasts by code.
    protocol GlobalDisclosureForecastStore {
        func find(_ code: String) -> GlobalDisclosureForecast?
        func save(_ item: GlobalDisclosureForecast)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalDisclosureForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalDisclosureForecastStore: GlobalDisclosureForecastStore {
        var items: [String: GlobalDisclosureForecast]
        var order: [String]

        init(items: [String: GlobalDisclosureForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalDisclosureForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalDisclosureForecast) {
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

        func list() -> [GlobalDisclosureForecast] {
            var out: [GlobalDisclosureForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalDisclosureForecastStore() -> any GlobalDisclosureForecastStore {
        return MemoryGlobalDisclosureForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalDisclosureForecastStore: GlobalDisclosureForecastStore {
        var inner: MemoryGlobalDisclosureForecastStore
        var cache: TTLCache<GlobalDisclosureForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalDisclosureForecastStore, cache: TTLCache<GlobalDisclosureForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalDisclosureForecast? {
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

        func save(_ item: GlobalDisclosureForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalDisclosureForecast] {
            return inner.list()
        }
    }

    static func newCachedGlobalDisclosureForecastStore(_ inner: MemoryGlobalDisclosureForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalDisclosureForecastStore {
        return CachedGlobalDisclosureForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global disclosure forecasts. Empty fields match all.
    final class GlobalDisclosureForecastQuery {
        var channel: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minAmount: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalDisclosureForecast) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalDisclosureForecast]) -> [GlobalDisclosureForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalDisclosureForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalDisclosureForecasts(_ store: any GlobalDisclosureForecastStore, query: GlobalDisclosureForecastQuery) -> [GlobalDisclosureForecast] {
        return query.apply(store.list())
    }
}
