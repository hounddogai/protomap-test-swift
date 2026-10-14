import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read forecasts by code.
    protocol ReadForecastStore {
        func find(_ code: String) -> ReadForecast?
        func save(_ item: ReadForecast)
        func remove(_ code: String) -> Bool
        func list() -> [ReadForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadForecastStore: ReadForecastStore {
        var items: [String: ReadForecast]
        var order: [String]

        init(items: [String: ReadForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadForecast) {
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

        func list() -> [ReadForecast] {
            var out: [ReadForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadForecastStore() -> any ReadForecastStore {
        return MemoryReadForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadForecastStore: ReadForecastStore {
        var inner: MemoryReadForecastStore
        var cache: TTLCache<ReadForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadForecastStore, cache: TTLCache<ReadForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadForecast? {
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

        func save(_ item: ReadForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadForecast] {
            return inner.list()
        }
    }

    static func newCachedReadForecastStore(_ inner: MemoryReadForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadForecastStore {
        return CachedReadForecastStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read forecasts. Empty fields match all.
    final class ReadForecastQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [ReadForecast]) -> [ReadForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadForecasts(_ store: any ReadForecastStore, query: ReadForecastQuery) -> [ReadForecast] {
        return query.apply(store.list())
    }
}
