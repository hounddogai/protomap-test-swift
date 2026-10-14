import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation forecasts by code.
    protocol IsolationForecastStore {
        func find(_ code: String) -> IsolationForecast?
        func save(_ item: IsolationForecast)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationForecastStore: IsolationForecastStore {
        var items: [String: IsolationForecast]
        var order: [String]

        init(items: [String: IsolationForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationForecast) {
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

        func list() -> [IsolationForecast] {
            var out: [IsolationForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationForecastStore() -> any IsolationForecastStore {
        return MemoryIsolationForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationForecastStore: IsolationForecastStore {
        var inner: MemoryIsolationForecastStore
        var cache: TTLCache<IsolationForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationForecastStore, cache: TTLCache<IsolationForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationForecast? {
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

        func save(_ item: IsolationForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationForecast] {
            return inner.list()
        }
    }

    static func newCachedIsolationForecastStore(_ inner: MemoryIsolationForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationForecastStore {
        return CachedIsolationForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation forecasts. Empty fields match all.
    final class IsolationForecastQuery {
        var country: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minVersion: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationForecast) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationForecast]) -> [IsolationForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationForecasts(_ store: any IsolationForecastStore, query: IsolationForecastQuery) -> [IsolationForecast] {
        return query.apply(store.list())
    }
}
