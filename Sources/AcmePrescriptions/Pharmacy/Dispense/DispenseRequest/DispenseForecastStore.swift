import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense forecasts by code.
    protocol DispenseForecastStore {
        func find(_ code: String) -> DispenseForecast?
        func save(_ item: DispenseForecast)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseForecastStore: DispenseForecastStore {
        var items: [String: DispenseForecast]
        var order: [String]

        init(items: [String: DispenseForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseForecast) {
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

        func list() -> [DispenseForecast] {
            var out: [DispenseForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseForecastStore() -> any DispenseForecastStore {
        return MemoryDispenseForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseForecastStore: DispenseForecastStore {
        var inner: MemoryDispenseForecastStore
        var cache: TTLCache<DispenseForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseForecastStore, cache: TTLCache<DispenseForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseForecast? {
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

        func save(_ item: DispenseForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseForecast] {
            return inner.list()
        }
    }

    static func newCachedDispenseForecastStore(_ inner: MemoryDispenseForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseForecastStore {
        return CachedDispenseForecastStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense forecasts. Empty fields match all.
    final class DispenseForecastQuery {
        var facility: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseForecast) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DispenseForecast]) -> [DispenseForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseForecasts(_ store: any DispenseForecastStore, query: DispenseForecastQuery) -> [DispenseForecast] {
        return query.apply(store.list())
    }
}
