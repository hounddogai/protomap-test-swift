import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rolling alert forecasts by code.
    protocol RollingAlertForecastStore {
        func find(_ code: String) -> RollingAlertForecast?
        func save(_ item: RollingAlertForecast)
        func remove(_ code: String) -> Bool
        func list() -> [RollingAlertForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingAlertForecastStore: RollingAlertForecastStore {
        var items: [String: RollingAlertForecast]
        var order: [String]

        init(items: [String: RollingAlertForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingAlertForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingAlertForecast) {
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

        func list() -> [RollingAlertForecast] {
            var out: [RollingAlertForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingAlertForecastStore() -> any RollingAlertForecastStore {
        return MemoryRollingAlertForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingAlertForecastStore: RollingAlertForecastStore {
        var inner: MemoryRollingAlertForecastStore
        var cache: TTLCache<RollingAlertForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingAlertForecastStore, cache: TTLCache<RollingAlertForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingAlertForecast? {
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

        func save(_ item: RollingAlertForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingAlertForecast] {
            return inner.list()
        }
    }

    static func newCachedRollingAlertForecastStore(_ inner: MemoryRollingAlertForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingAlertForecastStore {
        return CachedRollingAlertForecastStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling alert forecasts. Empty fields match all.
    final class RollingAlertForecastQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingAlertForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingAlertForecast]) -> [RollingAlertForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingAlertForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingAlertForecasts(_ store: any RollingAlertForecastStore, query: RollingAlertForecastQuery) -> [RollingAlertForecast] {
        return query.apply(store.list())
    }
}
