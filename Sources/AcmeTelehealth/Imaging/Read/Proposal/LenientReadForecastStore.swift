import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps lenient read forecasts by code.
    protocol LenientReadForecastStore {
        func find(_ code: String) -> LenientReadForecast?
        func save(_ item: LenientReadForecast)
        func remove(_ code: String) -> Bool
        func list() -> [LenientReadForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientReadForecastStore: LenientReadForecastStore {
        var items: [String: LenientReadForecast]
        var order: [String]

        init(items: [String: LenientReadForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientReadForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientReadForecast) {
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

        func list() -> [LenientReadForecast] {
            var out: [LenientReadForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientReadForecastStore() -> any LenientReadForecastStore {
        return MemoryLenientReadForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientReadForecastStore: LenientReadForecastStore {
        var inner: MemoryLenientReadForecastStore
        var cache: TTLCache<LenientReadForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientReadForecastStore, cache: TTLCache<LenientReadForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientReadForecast? {
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

        func save(_ item: LenientReadForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientReadForecast] {
            return inner.list()
        }
    }

    static func newCachedLenientReadForecastStore(_ inner: MemoryLenientReadForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientReadForecastStore {
        return CachedLenientReadForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient read forecasts. Empty fields match all.
    final class LenientReadForecastQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientReadForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientReadForecast]) -> [LenientReadForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientReadForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientReadForecasts(_ store: any LenientReadForecastStore, query: LenientReadForecastQuery) -> [LenientReadForecast] {
        return query.apply(store.list())
    }
}
