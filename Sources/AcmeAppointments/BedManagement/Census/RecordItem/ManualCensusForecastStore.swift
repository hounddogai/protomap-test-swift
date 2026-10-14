import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps manual census forecasts by code.
    protocol ManualCensusForecastStore {
        func find(_ code: String) -> ManualCensusForecast?
        func save(_ item: ManualCensusForecast)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCensusForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCensusForecastStore: ManualCensusForecastStore {
        var items: [String: ManualCensusForecast]
        var order: [String]

        init(items: [String: ManualCensusForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCensusForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCensusForecast) {
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

        func list() -> [ManualCensusForecast] {
            var out: [ManualCensusForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCensusForecastStore() -> any ManualCensusForecastStore {
        return MemoryManualCensusForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCensusForecastStore: ManualCensusForecastStore {
        var inner: MemoryManualCensusForecastStore
        var cache: TTLCache<ManualCensusForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCensusForecastStore, cache: TTLCache<ManualCensusForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCensusForecast? {
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

        func save(_ item: ManualCensusForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCensusForecast] {
            return inner.list()
        }
    }

    static func newCachedManualCensusForecastStore(_ inner: MemoryManualCensusForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCensusForecastStore {
        return CachedManualCensusForecastStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual census forecasts. Empty fields match all.
    final class ManualCensusForecastQuery {
        var category: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCensusForecast) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [ManualCensusForecast]) -> [ManualCensusForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCensusForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCensusForecasts(_ store: any ManualCensusForecastStore, query: ManualCensusForecastQuery) -> [ManualCensusForecast] {
        return query.apply(store.list())
    }
}
