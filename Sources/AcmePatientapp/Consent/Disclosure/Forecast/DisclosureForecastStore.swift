import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure forecasts by code.
    protocol DisclosureForecastStore {
        func find(_ code: String) -> DisclosureForecast?
        func save(_ item: DisclosureForecast)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureForecastStore: DisclosureForecastStore {
        var items: [String: DisclosureForecast]
        var order: [String]

        init(items: [String: DisclosureForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureForecast) {
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

        func list() -> [DisclosureForecast] {
            var out: [DisclosureForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureForecastStore() -> any DisclosureForecastStore {
        return MemoryDisclosureForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureForecastStore: DisclosureForecastStore {
        var inner: MemoryDisclosureForecastStore
        var cache: TTLCache<DisclosureForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureForecastStore, cache: TTLCache<DisclosureForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureForecast? {
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

        func save(_ item: DisclosureForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureForecast] {
            return inner.list()
        }
    }

    static func newCachedDisclosureForecastStore(_ inner: MemoryDisclosureForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureForecastStore {
        return CachedDisclosureForecastStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure forecasts. Empty fields match all.
    final class DisclosureForecastQuery {
        var category: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMargin: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureForecast) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DisclosureForecast]) -> [DisclosureForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureForecasts(_ store: any DisclosureForecastStore, query: DisclosureForecastQuery) -> [DisclosureForecast] {
        return query.apply(store.list())
    }
}
