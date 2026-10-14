import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps strict bed board forecasts by code.
    protocol StrictBedBoardForecastStore {
        func find(_ code: String) -> StrictBedBoardForecast?
        func save(_ item: StrictBedBoardForecast)
        func remove(_ code: String) -> Bool
        func list() -> [StrictBedBoardForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictBedBoardForecastStore: StrictBedBoardForecastStore {
        var items: [String: StrictBedBoardForecast]
        var order: [String]

        init(items: [String: StrictBedBoardForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictBedBoardForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictBedBoardForecast) {
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

        func list() -> [StrictBedBoardForecast] {
            var out: [StrictBedBoardForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictBedBoardForecastStore() -> any StrictBedBoardForecastStore {
        return MemoryStrictBedBoardForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictBedBoardForecastStore: StrictBedBoardForecastStore {
        var inner: MemoryStrictBedBoardForecastStore
        var cache: TTLCache<StrictBedBoardForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictBedBoardForecastStore, cache: TTLCache<StrictBedBoardForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictBedBoardForecast? {
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

        func save(_ item: StrictBedBoardForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictBedBoardForecast] {
            return inner.list()
        }
    }

    static func newCachedStrictBedBoardForecastStore(_ inner: MemoryStrictBedBoardForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictBedBoardForecastStore {
        return CachedStrictBedBoardForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict bed board forecasts. Empty fields match all.
    final class StrictBedBoardForecastQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictBedBoardForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictBedBoardForecast]) -> [StrictBedBoardForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictBedBoardForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictBedBoardForecasts(_ store: any StrictBedBoardForecastStore, query: StrictBedBoardForecastQuery) -> [StrictBedBoardForecast] {
        return query.apply(store.list())
    }
}
