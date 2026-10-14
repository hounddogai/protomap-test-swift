import AcmePlatform
import Foundation

extension Consent {
    /// Keeps regional proxy forecasts by code.
    protocol RegionalProxyForecastStore {
        func find(_ code: String) -> RegionalProxyForecast?
        func save(_ item: RegionalProxyForecast)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalProxyForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalProxyForecastStore: RegionalProxyForecastStore {
        var items: [String: RegionalProxyForecast]
        var order: [String]

        init(items: [String: RegionalProxyForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalProxyForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalProxyForecast) {
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

        func list() -> [RegionalProxyForecast] {
            var out: [RegionalProxyForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalProxyForecastStore() -> any RegionalProxyForecastStore {
        return MemoryRegionalProxyForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalProxyForecastStore: RegionalProxyForecastStore {
        var inner: MemoryRegionalProxyForecastStore
        var cache: TTLCache<RegionalProxyForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalProxyForecastStore, cache: TTLCache<RegionalProxyForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalProxyForecast? {
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

        func save(_ item: RegionalProxyForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalProxyForecast] {
            return inner.list()
        }
    }

    static func newCachedRegionalProxyForecastStore(_ inner: MemoryRegionalProxyForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalProxyForecastStore {
        return CachedRegionalProxyForecastStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional proxy forecasts. Empty fields match all.
    final class RegionalProxyForecastQuery {
        var title: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minLimit: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalProxyForecast) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalProxyForecast]) -> [RegionalProxyForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalProxyForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalProxyForecasts(_ store: any RegionalProxyForecastStore, query: RegionalProxyForecastQuery) -> [RegionalProxyForecast] {
        return query.apply(store.list())
    }
}
