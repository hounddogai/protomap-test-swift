import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps weighted study forecasts by code.
    protocol WeightedStudyForecastStore {
        func find(_ code: String) -> WeightedStudyForecast?
        func save(_ item: WeightedStudyForecast)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedStudyForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedStudyForecastStore: WeightedStudyForecastStore {
        var items: [String: WeightedStudyForecast]
        var order: [String]

        init(items: [String: WeightedStudyForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedStudyForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedStudyForecast) {
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

        func list() -> [WeightedStudyForecast] {
            var out: [WeightedStudyForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedStudyForecastStore() -> any WeightedStudyForecastStore {
        return MemoryWeightedStudyForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedStudyForecastStore: WeightedStudyForecastStore {
        var inner: MemoryWeightedStudyForecastStore
        var cache: TTLCache<WeightedStudyForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedStudyForecastStore, cache: TTLCache<WeightedStudyForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedStudyForecast? {
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

        func save(_ item: WeightedStudyForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedStudyForecast] {
            return inner.list()
        }
    }

    static func newCachedWeightedStudyForecastStore(_ inner: MemoryWeightedStudyForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedStudyForecastStore {
        return CachedWeightedStudyForecastStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted study forecasts. Empty fields match all.
    final class WeightedStudyForecastQuery {
        var ward: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedStudyForecast) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedStudyForecast]) -> [WeightedStudyForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedStudyForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedStudyForecasts(_ store: any WeightedStudyForecastStore, query: WeightedStudyForecastQuery) -> [WeightedStudyForecast] {
        return query.apply(store.list())
    }
}
