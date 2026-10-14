import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol forecasts by code.
    protocol CareProtocolForecastStore {
        func find(_ code: String) -> CareProtocolForecast?
        func save(_ item: CareProtocolForecast)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolForecastStore: CareProtocolForecastStore {
        var items: [String: CareProtocolForecast]
        var order: [String]

        init(items: [String: CareProtocolForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolForecast) {
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

        func list() -> [CareProtocolForecast] {
            var out: [CareProtocolForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolForecastStore() -> any CareProtocolForecastStore {
        return MemoryCareProtocolForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolForecastStore: CareProtocolForecastStore {
        var inner: MemoryCareProtocolForecastStore
        var cache: TTLCache<CareProtocolForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolForecastStore, cache: TTLCache<CareProtocolForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolForecast? {
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

        func save(_ item: CareProtocolForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolForecast] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolForecastStore(_ inner: MemoryCareProtocolForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolForecastStore {
        return CachedCareProtocolForecastStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol forecasts. Empty fields match all.
    final class CareProtocolForecastQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolForecast) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolForecast]) -> [CareProtocolForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolForecasts(_ store: any CareProtocolForecastStore, query: CareProtocolForecastQuery) -> [CareProtocolForecast] {
        return query.apply(store.list())
    }
}
