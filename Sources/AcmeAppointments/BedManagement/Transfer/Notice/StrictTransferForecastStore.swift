import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps strict transfer forecasts by code.
    protocol StrictTransferForecastStore {
        func find(_ code: String) -> StrictTransferForecast?
        func save(_ item: StrictTransferForecast)
        func remove(_ code: String) -> Bool
        func list() -> [StrictTransferForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictTransferForecastStore: StrictTransferForecastStore {
        var items: [String: StrictTransferForecast]
        var order: [String]

        init(items: [String: StrictTransferForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictTransferForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictTransferForecast) {
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

        func list() -> [StrictTransferForecast] {
            var out: [StrictTransferForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictTransferForecastStore() -> any StrictTransferForecastStore {
        return MemoryStrictTransferForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictTransferForecastStore: StrictTransferForecastStore {
        var inner: MemoryStrictTransferForecastStore
        var cache: TTLCache<StrictTransferForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictTransferForecastStore, cache: TTLCache<StrictTransferForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictTransferForecast? {
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

        func save(_ item: StrictTransferForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictTransferForecast] {
            return inner.list()
        }
    }

    static func newCachedStrictTransferForecastStore(_ inner: MemoryStrictTransferForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictTransferForecastStore {
        return CachedStrictTransferForecastStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict transfer forecasts. Empty fields match all.
    final class StrictTransferForecastQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictTransferForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [StrictTransferForecast]) -> [StrictTransferForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictTransferForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictTransferForecasts(_ store: any StrictTransferForecastStore, query: StrictTransferForecastQuery) -> [StrictTransferForecast] {
        return query.apply(store.list())
    }
}
