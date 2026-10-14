import AcmePlatform
import Foundation

extension Labs {
    /// Keeps tiered panel forecasts by code.
    protocol TieredPanelForecastStore {
        func find(_ code: String) -> TieredPanelForecast?
        func save(_ item: TieredPanelForecast)
        func remove(_ code: String) -> Bool
        func list() -> [TieredPanelForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredPanelForecastStore: TieredPanelForecastStore {
        var items: [String: TieredPanelForecast]
        var order: [String]

        init(items: [String: TieredPanelForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredPanelForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredPanelForecast) {
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

        func list() -> [TieredPanelForecast] {
            var out: [TieredPanelForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredPanelForecastStore() -> any TieredPanelForecastStore {
        return MemoryTieredPanelForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredPanelForecastStore: TieredPanelForecastStore {
        var inner: MemoryTieredPanelForecastStore
        var cache: TTLCache<TieredPanelForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredPanelForecastStore, cache: TTLCache<TieredPanelForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredPanelForecast? {
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

        func save(_ item: TieredPanelForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredPanelForecast] {
            return inner.list()
        }
    }

    static func newCachedTieredPanelForecastStore(_ inner: MemoryTieredPanelForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredPanelForecastStore {
        return CachedTieredPanelForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered panel forecasts. Empty fields match all.
    final class TieredPanelForecastQuery {
        var ward: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredPanelForecast) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [TieredPanelForecast]) -> [TieredPanelForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredPanelForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredPanelForecasts(_ store: any TieredPanelForecastStore, query: TieredPanelForecastQuery) -> [TieredPanelForecast] {
        return query.apply(store.list())
    }
}
