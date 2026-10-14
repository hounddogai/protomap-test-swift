import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy reference range forecasts by code.
    protocol LegacyReferenceRangeForecastStore {
        func find(_ code: String) -> LegacyReferenceRangeForecast?
        func save(_ item: LegacyReferenceRangeForecast)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyReferenceRangeForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyReferenceRangeForecastStore: LegacyReferenceRangeForecastStore {
        var items: [String: LegacyReferenceRangeForecast]
        var order: [String]

        init(items: [String: LegacyReferenceRangeForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyReferenceRangeForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyReferenceRangeForecast) {
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

        func list() -> [LegacyReferenceRangeForecast] {
            var out: [LegacyReferenceRangeForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyReferenceRangeForecastStore() -> any LegacyReferenceRangeForecastStore {
        return MemoryLegacyReferenceRangeForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyReferenceRangeForecastStore: LegacyReferenceRangeForecastStore {
        var inner: MemoryLegacyReferenceRangeForecastStore
        var cache: TTLCache<LegacyReferenceRangeForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyReferenceRangeForecastStore, cache: TTLCache<LegacyReferenceRangeForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyReferenceRangeForecast? {
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

        func save(_ item: LegacyReferenceRangeForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyReferenceRangeForecast] {
            return inner.list()
        }
    }

    static func newCachedLegacyReferenceRangeForecastStore(_ inner: MemoryLegacyReferenceRangeForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyReferenceRangeForecastStore {
        return CachedLegacyReferenceRangeForecastStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy reference range forecasts. Empty fields match all.
    final class LegacyReferenceRangeForecastQuery {
        var label: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyReferenceRangeForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyReferenceRangeForecast]) -> [LegacyReferenceRangeForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyReferenceRangeForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyReferenceRangeForecasts(_ store: any LegacyReferenceRangeForecastStore, query: LegacyReferenceRangeForecastQuery) -> [LegacyReferenceRangeForecast] {
        return query.apply(store.list())
    }
}
