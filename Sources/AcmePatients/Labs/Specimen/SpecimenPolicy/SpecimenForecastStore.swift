import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen forecasts by code.
    protocol SpecimenForecastStore {
        func find(_ code: String) -> SpecimenForecast?
        func save(_ item: SpecimenForecast)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenForecastStore: SpecimenForecastStore {
        var items: [String: SpecimenForecast]
        var order: [String]

        init(items: [String: SpecimenForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenForecast) {
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

        func list() -> [SpecimenForecast] {
            var out: [SpecimenForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenForecastStore() -> any SpecimenForecastStore {
        return MemorySpecimenForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenForecastStore: SpecimenForecastStore {
        var inner: MemorySpecimenForecastStore
        var cache: TTLCache<SpecimenForecast>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenForecastStore, cache: TTLCache<SpecimenForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenForecast? {
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

        func save(_ item: SpecimenForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenForecast] {
            return inner.list()
        }
    }

    static func newCachedSpecimenForecastStore(_ inner: MemorySpecimenForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenForecastStore {
        return CachedSpecimenForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen forecasts. Empty fields match all.
    final class SpecimenForecastQuery {
        var segment: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minWeight: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenForecast) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenForecast]) -> [SpecimenForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenForecasts(_ store: any SpecimenForecastStore, query: SpecimenForecastQuery) -> [SpecimenForecast] {
        return query.apply(store.list())
    }
}
