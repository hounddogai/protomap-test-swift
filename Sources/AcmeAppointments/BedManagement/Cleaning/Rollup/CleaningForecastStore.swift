import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning forecasts by code.
    protocol CleaningForecastStore {
        func find(_ code: String) -> CleaningForecast?
        func save(_ item: CleaningForecast)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningForecastStore: CleaningForecastStore {
        var items: [String: CleaningForecast]
        var order: [String]

        init(items: [String: CleaningForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningForecast) {
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

        func list() -> [CleaningForecast] {
            var out: [CleaningForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningForecastStore() -> any CleaningForecastStore {
        return MemoryCleaningForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningForecastStore: CleaningForecastStore {
        var inner: MemoryCleaningForecastStore
        var cache: TTLCache<CleaningForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningForecastStore, cache: TTLCache<CleaningForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningForecast? {
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

        func save(_ item: CleaningForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningForecast] {
            return inner.list()
        }
    }

    static func newCachedCleaningForecastStore(_ inner: MemoryCleaningForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningForecastStore {
        return CachedCleaningForecastStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning forecasts. Empty fields match all.
    final class CleaningForecastQuery {
        var country: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minLimit: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningForecast) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [CleaningForecast]) -> [CleaningForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningForecasts(_ store: any CleaningForecastStore, query: CleaningForecastQuery) -> [CleaningForecast] {
        return query.apply(store.list())
    }
}
