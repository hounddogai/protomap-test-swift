import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps manual remittance forecasts by code.
    protocol ManualRemittanceForecastStore {
        func find(_ code: String) -> ManualRemittanceForecast?
        func save(_ item: ManualRemittanceForecast)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRemittanceForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRemittanceForecastStore: ManualRemittanceForecastStore {
        var items: [String: ManualRemittanceForecast]
        var order: [String]

        init(items: [String: ManualRemittanceForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRemittanceForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRemittanceForecast) {
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

        func list() -> [ManualRemittanceForecast] {
            var out: [ManualRemittanceForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRemittanceForecastStore() -> any ManualRemittanceForecastStore {
        return MemoryManualRemittanceForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRemittanceForecastStore: ManualRemittanceForecastStore {
        var inner: MemoryManualRemittanceForecastStore
        var cache: TTLCache<ManualRemittanceForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRemittanceForecastStore, cache: TTLCache<ManualRemittanceForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRemittanceForecast? {
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

        func save(_ item: ManualRemittanceForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRemittanceForecast] {
            return inner.list()
        }
    }

    static func newCachedManualRemittanceForecastStore(_ inner: MemoryManualRemittanceForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRemittanceForecastStore {
        return CachedManualRemittanceForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual remittance forecasts. Empty fields match all.
    final class ManualRemittanceForecastQuery {
        var country: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minRetries: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRemittanceForecast) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualRemittanceForecast]) -> [ManualRemittanceForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRemittanceForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRemittanceForecasts(_ store: any ManualRemittanceForecastStore, query: ManualRemittanceForecastQuery) -> [ManualRemittanceForecast] {
        return query.apply(store.list())
    }
}
