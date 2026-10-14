import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps modality forecasts by code.
    protocol ModalityForecastStore {
        func find(_ code: String) -> ModalityForecast?
        func save(_ item: ModalityForecast)
        func remove(_ code: String) -> Bool
        func list() -> [ModalityForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryModalityForecastStore: ModalityForecastStore {
        var items: [String: ModalityForecast]
        var order: [String]

        init(items: [String: ModalityForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ModalityForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ModalityForecast) {
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

        func list() -> [ModalityForecast] {
            var out: [ModalityForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryModalityForecastStore() -> any ModalityForecastStore {
        return MemoryModalityForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedModalityForecastStore: ModalityForecastStore {
        var inner: MemoryModalityForecastStore
        var cache: TTLCache<ModalityForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryModalityForecastStore, cache: TTLCache<ModalityForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ModalityForecast? {
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

        func save(_ item: ModalityForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ModalityForecast] {
            return inner.list()
        }
    }

    static func newCachedModalityForecastStore(_ inner: MemoryModalityForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ModalityForecastStore {
        return CachedModalityForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects modality forecasts. Empty fields match all.
    final class ModalityForecastQuery {
        var ward: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ModalityForecast) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ModalityForecast]) -> [ModalityForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ModalityForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findModalityForecasts(_ store: any ModalityForecastStore, query: ModalityForecastQuery) -> [ModalityForecast] {
        return query.apply(store.list())
    }
}
