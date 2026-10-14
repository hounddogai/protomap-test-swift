import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps regional substitution forecasts by code.
    protocol RegionalSubstitutionForecastStore {
        func find(_ code: String) -> RegionalSubstitutionForecast?
        func save(_ item: RegionalSubstitutionForecast)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalSubstitutionForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalSubstitutionForecastStore: RegionalSubstitutionForecastStore {
        var items: [String: RegionalSubstitutionForecast]
        var order: [String]

        init(items: [String: RegionalSubstitutionForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalSubstitutionForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalSubstitutionForecast) {
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

        func list() -> [RegionalSubstitutionForecast] {
            var out: [RegionalSubstitutionForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalSubstitutionForecastStore() -> any RegionalSubstitutionForecastStore {
        return MemoryRegionalSubstitutionForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalSubstitutionForecastStore: RegionalSubstitutionForecastStore {
        var inner: MemoryRegionalSubstitutionForecastStore
        var cache: TTLCache<RegionalSubstitutionForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalSubstitutionForecastStore, cache: TTLCache<RegionalSubstitutionForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalSubstitutionForecast? {
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

        func save(_ item: RegionalSubstitutionForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalSubstitutionForecast] {
            return inner.list()
        }
    }

    static func newCachedRegionalSubstitutionForecastStore(_ inner: MemoryRegionalSubstitutionForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalSubstitutionForecastStore {
        return CachedRegionalSubstitutionForecastStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional substitution forecasts. Empty fields match all.
    final class RegionalSubstitutionForecastQuery {
        var name: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalSubstitutionForecast) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalSubstitutionForecast]) -> [RegionalSubstitutionForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalSubstitutionForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalSubstitutionForecasts(_ store: any RegionalSubstitutionForecastStore, query: RegionalSubstitutionForecastQuery) -> [RegionalSubstitutionForecast] {
        return query.apply(store.list())
    }
}
