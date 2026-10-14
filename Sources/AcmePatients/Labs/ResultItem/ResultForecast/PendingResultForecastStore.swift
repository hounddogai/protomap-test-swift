import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending result forecasts by code.
    protocol PendingResultForecastStore {
        func find(_ code: String) -> PendingResultForecast?
        func save(_ item: PendingResultForecast)
        func remove(_ code: String) -> Bool
        func list() -> [PendingResultForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingResultForecastStore: PendingResultForecastStore {
        var items: [String: PendingResultForecast]
        var order: [String]

        init(items: [String: PendingResultForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingResultForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingResultForecast) {
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

        func list() -> [PendingResultForecast] {
            var out: [PendingResultForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingResultForecastStore() -> any PendingResultForecastStore {
        return MemoryPendingResultForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingResultForecastStore: PendingResultForecastStore {
        var inner: MemoryPendingResultForecastStore
        var cache: TTLCache<PendingResultForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingResultForecastStore, cache: TTLCache<PendingResultForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingResultForecast? {
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

        func save(_ item: PendingResultForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingResultForecast] {
            return inner.list()
        }
    }

    static func newCachedPendingResultForecastStore(_ inner: MemoryPendingResultForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingResultForecastStore {
        return CachedPendingResultForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending result forecasts. Empty fields match all.
    final class PendingResultForecastQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingResultForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingResultForecast]) -> [PendingResultForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingResultForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingResultForecasts(_ store: any PendingResultForecastStore, query: PendingResultForecastQuery) -> [PendingResultForecast] {
        return query.apply(store.list())
    }
}
