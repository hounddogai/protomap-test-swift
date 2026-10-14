import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending read forecasts by code.
    protocol PendingReadForecastStore {
        func find(_ code: String) -> PendingReadForecast?
        func save(_ item: PendingReadForecast)
        func remove(_ code: String) -> Bool
        func list() -> [PendingReadForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingReadForecastStore: PendingReadForecastStore {
        var items: [String: PendingReadForecast]
        var order: [String]

        init(items: [String: PendingReadForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingReadForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingReadForecast) {
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

        func list() -> [PendingReadForecast] {
            var out: [PendingReadForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingReadForecastStore() -> any PendingReadForecastStore {
        return MemoryPendingReadForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingReadForecastStore: PendingReadForecastStore {
        var inner: MemoryPendingReadForecastStore
        var cache: TTLCache<PendingReadForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingReadForecastStore, cache: TTLCache<PendingReadForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingReadForecast? {
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

        func save(_ item: PendingReadForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingReadForecast] {
            return inner.list()
        }
    }

    static func newCachedPendingReadForecastStore(_ inner: MemoryPendingReadForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingReadForecastStore {
        return CachedPendingReadForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending read forecasts. Empty fields match all.
    final class PendingReadForecastQuery {
        var region: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingReadForecast) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [PendingReadForecast]) -> [PendingReadForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingReadForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingReadForecasts(_ store: any PendingReadForecastStore, query: PendingReadForecastQuery) -> [PendingReadForecast] {
        return query.apply(store.list())
    }
}
