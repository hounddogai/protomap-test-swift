import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps global alert forecasts by code.
    protocol GlobalAlertForecastStore {
        func find(_ code: String) -> GlobalAlertForecast?
        func save(_ item: GlobalAlertForecast)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalAlertForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalAlertForecastStore: GlobalAlertForecastStore {
        var items: [String: GlobalAlertForecast]
        var order: [String]

        init(items: [String: GlobalAlertForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalAlertForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalAlertForecast) {
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

        func list() -> [GlobalAlertForecast] {
            var out: [GlobalAlertForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalAlertForecastStore() -> any GlobalAlertForecastStore {
        return MemoryGlobalAlertForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalAlertForecastStore: GlobalAlertForecastStore {
        var inner: MemoryGlobalAlertForecastStore
        var cache: TTLCache<GlobalAlertForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalAlertForecastStore, cache: TTLCache<GlobalAlertForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalAlertForecast? {
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

        func save(_ item: GlobalAlertForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalAlertForecast] {
            return inner.list()
        }
    }

    static func newCachedGlobalAlertForecastStore(_ inner: MemoryGlobalAlertForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalAlertForecastStore {
        return CachedGlobalAlertForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global alert forecasts. Empty fields match all.
    final class GlobalAlertForecastQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalAlertForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [GlobalAlertForecast]) -> [GlobalAlertForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalAlertForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalAlertForecasts(_ store: any GlobalAlertForecastStore, query: GlobalAlertForecastQuery) -> [GlobalAlertForecast] {
        return query.apply(store.list())
    }
}
