import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board forecasts by code.
    protocol BedBoardForecastStore {
        func find(_ code: String) -> BedBoardForecast?
        func save(_ item: BedBoardForecast)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardForecastStore: BedBoardForecastStore {
        var items: [String: BedBoardForecast]
        var order: [String]

        init(items: [String: BedBoardForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardForecast) {
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

        func list() -> [BedBoardForecast] {
            var out: [BedBoardForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardForecastStore() -> any BedBoardForecastStore {
        return MemoryBedBoardForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardForecastStore: BedBoardForecastStore {
        var inner: MemoryBedBoardForecastStore
        var cache: TTLCache<BedBoardForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardForecastStore, cache: TTLCache<BedBoardForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardForecast? {
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

        func save(_ item: BedBoardForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardForecast] {
            return inner.list()
        }
    }

    static func newCachedBedBoardForecastStore(_ inner: MemoryBedBoardForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardForecastStore {
        return CachedBedBoardForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board forecasts. Empty fields match all.
    final class BedBoardForecastQuery {
        var facility: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minAmount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardForecast) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardForecast]) -> [BedBoardForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardForecasts(_ store: any BedBoardForecastStore, query: BedBoardForecastQuery) -> [BedBoardForecast] {
        return query.apply(store.list())
    }
}
