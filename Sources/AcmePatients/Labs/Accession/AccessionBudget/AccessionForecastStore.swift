import AcmePlatform
import Foundation

extension Labs {
    /// Keeps accession forecasts by code.
    protocol AccessionForecastStore {
        func find(_ code: String) -> AccessionForecast?
        func save(_ item: AccessionForecast)
        func remove(_ code: String) -> Bool
        func list() -> [AccessionForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAccessionForecastStore: AccessionForecastStore {
        var items: [String: AccessionForecast]
        var order: [String]

        init(items: [String: AccessionForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AccessionForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AccessionForecast) {
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

        func list() -> [AccessionForecast] {
            var out: [AccessionForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAccessionForecastStore() -> any AccessionForecastStore {
        return MemoryAccessionForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAccessionForecastStore: AccessionForecastStore {
        var inner: MemoryAccessionForecastStore
        var cache: TTLCache<AccessionForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryAccessionForecastStore, cache: TTLCache<AccessionForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AccessionForecast? {
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

        func save(_ item: AccessionForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AccessionForecast] {
            return inner.list()
        }
    }

    static func newCachedAccessionForecastStore(_ inner: MemoryAccessionForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AccessionForecastStore {
        return CachedAccessionForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects accession forecasts. Empty fields match all.
    final class AccessionForecastQuery {
        var ward: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AccessionForecast) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AccessionForecast]) -> [AccessionForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AccessionForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAccessionForecasts(_ store: any AccessionForecastStore, query: AccessionForecastQuery) -> [AccessionForecast] {
        return query.apply(store.list())
    }
}
