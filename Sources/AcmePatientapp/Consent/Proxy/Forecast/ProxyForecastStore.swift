import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy forecasts by code.
    protocol ProxyForecastStore {
        func find(_ code: String) -> ProxyForecast?
        func save(_ item: ProxyForecast)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyForecastStore: ProxyForecastStore {
        var items: [String: ProxyForecast]
        var order: [String]

        init(items: [String: ProxyForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyForecast) {
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

        func list() -> [ProxyForecast] {
            var out: [ProxyForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyForecastStore() -> any ProxyForecastStore {
        return MemoryProxyForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyForecastStore: ProxyForecastStore {
        var inner: MemoryProxyForecastStore
        var cache: TTLCache<ProxyForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyForecastStore, cache: TTLCache<ProxyForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyForecast? {
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

        func save(_ item: ProxyForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyForecast] {
            return inner.list()
        }
    }

    static func newCachedProxyForecastStore(_ inner: MemoryProxyForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyForecastStore {
        return CachedProxyForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy forecasts. Empty fields match all.
    final class ProxyForecastQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyForecast) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ProxyForecast]) -> [ProxyForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyForecasts(_ store: any ProxyForecastStore, query: ProxyForecastQuery) -> [ProxyForecast] {
        return query.apply(store.list())
    }
}
