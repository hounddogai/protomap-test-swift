import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling disclosure forecasts by code.
    protocol RollingDisclosureForecastStore {
        func find(_ code: String) -> RollingDisclosureForecast?
        func save(_ item: RollingDisclosureForecast)
        func remove(_ code: String) -> Bool
        func list() -> [RollingDisclosureForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingDisclosureForecastStore: RollingDisclosureForecastStore {
        var items: [String: RollingDisclosureForecast]
        var order: [String]

        init(items: [String: RollingDisclosureForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingDisclosureForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingDisclosureForecast) {
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

        func list() -> [RollingDisclosureForecast] {
            var out: [RollingDisclosureForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingDisclosureForecastStore() -> any RollingDisclosureForecastStore {
        return MemoryRollingDisclosureForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingDisclosureForecastStore: RollingDisclosureForecastStore {
        var inner: MemoryRollingDisclosureForecastStore
        var cache: TTLCache<RollingDisclosureForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingDisclosureForecastStore, cache: TTLCache<RollingDisclosureForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingDisclosureForecast? {
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

        func save(_ item: RollingDisclosureForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingDisclosureForecast] {
            return inner.list()
        }
    }

    static func newCachedRollingDisclosureForecastStore(_ inner: MemoryRollingDisclosureForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingDisclosureForecastStore {
        return CachedRollingDisclosureForecastStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling disclosure forecasts. Empty fields match all.
    final class RollingDisclosureForecastQuery {
        var country: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minMargin: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingDisclosureForecast) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [RollingDisclosureForecast]) -> [RollingDisclosureForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingDisclosureForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingDisclosureForecasts(_ store: any RollingDisclosureForecastStore, query: RollingDisclosureForecastQuery) -> [RollingDisclosureForecast] {
        return query.apply(store.list())
    }
}
