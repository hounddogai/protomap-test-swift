import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default shift forecasts by code.
    protocol DefaultShiftForecastStore {
        func find(_ code: String) -> DefaultShiftForecast?
        func save(_ item: DefaultShiftForecast)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultShiftForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultShiftForecastStore: DefaultShiftForecastStore {
        var items: [String: DefaultShiftForecast]
        var order: [String]

        init(items: [String: DefaultShiftForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultShiftForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultShiftForecast) {
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

        func list() -> [DefaultShiftForecast] {
            var out: [DefaultShiftForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultShiftForecastStore() -> any DefaultShiftForecastStore {
        return MemoryDefaultShiftForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultShiftForecastStore: DefaultShiftForecastStore {
        var inner: MemoryDefaultShiftForecastStore
        var cache: TTLCache<DefaultShiftForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultShiftForecastStore, cache: TTLCache<DefaultShiftForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultShiftForecast? {
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

        func save(_ item: DefaultShiftForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultShiftForecast] {
            return inner.list()
        }
    }

    static func newCachedDefaultShiftForecastStore(_ inner: MemoryDefaultShiftForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultShiftForecastStore {
        return CachedDefaultShiftForecastStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default shift forecasts. Empty fields match all.
    final class DefaultShiftForecastQuery {
        var ward: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultShiftForecast) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultShiftForecast]) -> [DefaultShiftForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultShiftForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultShiftForecasts(_ store: any DefaultShiftForecastStore, query: DefaultShiftForecastQuery) -> [DefaultShiftForecast] {
        return query.apply(store.list())
    }
}
