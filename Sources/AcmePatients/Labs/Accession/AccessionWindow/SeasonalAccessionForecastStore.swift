import AcmePlatform
import Foundation

extension Labs {
    /// Keeps seasonal accession forecasts by code.
    protocol SeasonalAccessionForecastStore {
        func find(_ code: String) -> SeasonalAccessionForecast?
        func save(_ item: SeasonalAccessionForecast)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalAccessionForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalAccessionForecastStore: SeasonalAccessionForecastStore {
        var items: [String: SeasonalAccessionForecast]
        var order: [String]

        init(items: [String: SeasonalAccessionForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalAccessionForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalAccessionForecast) {
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

        func list() -> [SeasonalAccessionForecast] {
            var out: [SeasonalAccessionForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalAccessionForecastStore() -> any SeasonalAccessionForecastStore {
        return MemorySeasonalAccessionForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalAccessionForecastStore: SeasonalAccessionForecastStore {
        var inner: MemorySeasonalAccessionForecastStore
        var cache: TTLCache<SeasonalAccessionForecast>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalAccessionForecastStore, cache: TTLCache<SeasonalAccessionForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalAccessionForecast? {
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

        func save(_ item: SeasonalAccessionForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalAccessionForecast] {
            return inner.list()
        }
    }

    static func newCachedSeasonalAccessionForecastStore(_ inner: MemorySeasonalAccessionForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalAccessionForecastStore {
        return CachedSeasonalAccessionForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal accession forecasts. Empty fields match all.
    final class SeasonalAccessionForecastQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalAccessionForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalAccessionForecast]) -> [SeasonalAccessionForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalAccessionForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalAccessionForecasts(_ store: any SeasonalAccessionForecastStore, query: SeasonalAccessionForecastQuery) -> [SeasonalAccessionForecast] {
        return query.apply(store.list())
    }
}
