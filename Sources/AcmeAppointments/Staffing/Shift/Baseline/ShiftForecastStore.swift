import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift forecasts by code.
    protocol ShiftForecastStore {
        func find(_ code: String) -> ShiftForecast?
        func save(_ item: ShiftForecast)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftForecastStore: ShiftForecastStore {
        var items: [String: ShiftForecast]
        var order: [String]

        init(items: [String: ShiftForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftForecast) {
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

        func list() -> [ShiftForecast] {
            var out: [ShiftForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftForecastStore() -> any ShiftForecastStore {
        return MemoryShiftForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftForecastStore: ShiftForecastStore {
        var inner: MemoryShiftForecastStore
        var cache: TTLCache<ShiftForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftForecastStore, cache: TTLCache<ShiftForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftForecast? {
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

        func save(_ item: ShiftForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftForecast] {
            return inner.list()
        }
    }

    static func newCachedShiftForecastStore(_ inner: MemoryShiftForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftForecastStore {
        return CachedShiftForecastStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift forecasts. Empty fields match all.
    final class ShiftForecastQuery {
        var title: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftForecast) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftForecast]) -> [ShiftForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftForecasts(_ store: any ShiftForecastStore, query: ShiftForecastQuery) -> [ShiftForecast] {
        return query.apply(store.list())
    }
}
