import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling language forecasts by code.
    protocol RollingLanguageForecastStore {
        func find(_ code: String) -> RollingLanguageForecast?
        func save(_ item: RollingLanguageForecast)
        func remove(_ code: String) -> Bool
        func list() -> [RollingLanguageForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingLanguageForecastStore: RollingLanguageForecastStore {
        var items: [String: RollingLanguageForecast]
        var order: [String]

        init(items: [String: RollingLanguageForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingLanguageForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingLanguageForecast) {
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

        func list() -> [RollingLanguageForecast] {
            var out: [RollingLanguageForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingLanguageForecastStore() -> any RollingLanguageForecastStore {
        return MemoryRollingLanguageForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingLanguageForecastStore: RollingLanguageForecastStore {
        var inner: MemoryRollingLanguageForecastStore
        var cache: TTLCache<RollingLanguageForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingLanguageForecastStore, cache: TTLCache<RollingLanguageForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingLanguageForecast? {
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

        func save(_ item: RollingLanguageForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingLanguageForecast] {
            return inner.list()
        }
    }

    static func newCachedRollingLanguageForecastStore(_ inner: MemoryRollingLanguageForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingLanguageForecastStore {
        return CachedRollingLanguageForecastStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling language forecasts. Empty fields match all.
    final class RollingLanguageForecastQuery {
        var segment: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingLanguageForecast) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [RollingLanguageForecast]) -> [RollingLanguageForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingLanguageForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingLanguageForecasts(_ store: any RollingLanguageForecastStore, query: RollingLanguageForecastQuery) -> [RollingLanguageForecast] {
        return query.apply(store.list())
    }
}
