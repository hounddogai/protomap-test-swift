import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel forecasts by code.
    protocol PanelForecastStore {
        func find(_ code: String) -> PanelForecast?
        func save(_ item: PanelForecast)
        func remove(_ code: String) -> Bool
        func list() -> [PanelForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelForecastStore: PanelForecastStore {
        var items: [String: PanelForecast]
        var order: [String]

        init(items: [String: PanelForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelForecast) {
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

        func list() -> [PanelForecast] {
            var out: [PanelForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelForecastStore() -> any PanelForecastStore {
        return MemoryPanelForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelForecastStore: PanelForecastStore {
        var inner: MemoryPanelForecastStore
        var cache: TTLCache<PanelForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelForecastStore, cache: TTLCache<PanelForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelForecast? {
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

        func save(_ item: PanelForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelForecast] {
            return inner.list()
        }
    }

    static func newCachedPanelForecastStore(_ inner: MemoryPanelForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelForecastStore {
        return CachedPanelForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel forecasts. Empty fields match all.
    final class PanelForecastQuery {
        var label: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PanelForecast]) -> [PanelForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelForecasts(_ store: any PanelForecastStore, query: PanelForecastQuery) -> [PanelForecast] {
        return query.apply(store.list())
    }
}
