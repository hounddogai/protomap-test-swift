import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set forecasts by code.
    protocol OrderSetForecastStore {
        func find(_ code: String) -> OrderSetForecast?
        func save(_ item: OrderSetForecast)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetForecastStore: OrderSetForecastStore {
        var items: [String: OrderSetForecast]
        var order: [String]

        init(items: [String: OrderSetForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetForecast) {
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

        func list() -> [OrderSetForecast] {
            var out: [OrderSetForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetForecastStore() -> any OrderSetForecastStore {
        return MemoryOrderSetForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetForecastStore: OrderSetForecastStore {
        var inner: MemoryOrderSetForecastStore
        var cache: TTLCache<OrderSetForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetForecastStore, cache: TTLCache<OrderSetForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetForecast? {
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

        func save(_ item: OrderSetForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetForecast] {
            return inner.list()
        }
    }

    static func newCachedOrderSetForecastStore(_ inner: MemoryOrderSetForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetForecastStore {
        return CachedOrderSetForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set forecasts. Empty fields match all.
    final class OrderSetForecastQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetForecast]) -> [OrderSetForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetForecasts(_ store: any OrderSetForecastStore, query: OrderSetForecastQuery) -> [OrderSetForecast] {
        return query.apply(store.list())
    }
}
