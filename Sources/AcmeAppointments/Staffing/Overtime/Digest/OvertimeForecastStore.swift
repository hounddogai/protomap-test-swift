import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime forecasts by code.
    protocol OvertimeForecastStore {
        func find(_ code: String) -> OvertimeForecast?
        func save(_ item: OvertimeForecast)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeForecastStore: OvertimeForecastStore {
        var items: [String: OvertimeForecast]
        var order: [String]

        init(items: [String: OvertimeForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeForecast) {
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

        func list() -> [OvertimeForecast] {
            var out: [OvertimeForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeForecastStore() -> any OvertimeForecastStore {
        return MemoryOvertimeForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeForecastStore: OvertimeForecastStore {
        var inner: MemoryOvertimeForecastStore
        var cache: TTLCache<OvertimeForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeForecastStore, cache: TTLCache<OvertimeForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeForecast? {
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

        func save(_ item: OvertimeForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeForecast] {
            return inner.list()
        }
    }

    static func newCachedOvertimeForecastStore(_ inner: MemoryOvertimeForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeForecastStore {
        return CachedOvertimeForecastStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime forecasts. Empty fields match all.
    final class OvertimeForecastQuery {
        var ward: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeForecast) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [OvertimeForecast]) -> [OvertimeForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeForecasts(_ store: any OvertimeForecastStore, query: OvertimeForecastQuery) -> [OvertimeForecast] {
        return query.apply(store.list())
    }
}
