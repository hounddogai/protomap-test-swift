import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network forecasts by code.
    protocol NetworkForecastStore {
        func find(_ code: String) -> NetworkForecast?
        func save(_ item: NetworkForecast)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkForecastStore: NetworkForecastStore {
        var items: [String: NetworkForecast]
        var order: [String]

        init(items: [String: NetworkForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkForecast) {
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

        func list() -> [NetworkForecast] {
            var out: [NetworkForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkForecastStore() -> any NetworkForecastStore {
        return MemoryNetworkForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkForecastStore: NetworkForecastStore {
        var inner: MemoryNetworkForecastStore
        var cache: TTLCache<NetworkForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkForecastStore, cache: TTLCache<NetworkForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkForecast? {
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

        func save(_ item: NetworkForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkForecast] {
            return inner.list()
        }
    }

    static func newCachedNetworkForecastStore(_ inner: MemoryNetworkForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkForecastStore {
        return CachedNetworkForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network forecasts. Empty fields match all.
    final class NetworkForecastQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkForecast) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkForecast]) -> [NetworkForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkForecasts(_ store: any NetworkForecastStore, query: NetworkForecastQuery) -> [NetworkForecast] {
        return query.apply(store.list())
    }
}
