import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range forecasts by code.
    protocol ReferenceRangeForecastStore {
        func find(_ code: String) -> ReferenceRangeForecast?
        func save(_ item: ReferenceRangeForecast)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeForecastStore: ReferenceRangeForecastStore {
        var items: [String: ReferenceRangeForecast]
        var order: [String]

        init(items: [String: ReferenceRangeForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeForecast) {
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

        func list() -> [ReferenceRangeForecast] {
            var out: [ReferenceRangeForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeForecastStore() -> any ReferenceRangeForecastStore {
        return MemoryReferenceRangeForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeForecastStore: ReferenceRangeForecastStore {
        var inner: MemoryReferenceRangeForecastStore
        var cache: TTLCache<ReferenceRangeForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeForecastStore, cache: TTLCache<ReferenceRangeForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeForecast? {
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

        func save(_ item: ReferenceRangeForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeForecast] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeForecastStore(_ inner: MemoryReferenceRangeForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeForecastStore {
        return CachedReferenceRangeForecastStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range forecasts. Empty fields match all.
    final class ReferenceRangeForecastQuery {
        var segment: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeForecast) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeForecast]) -> [ReferenceRangeForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeForecasts(_ store: any ReferenceRangeForecastStore, query: ReferenceRangeForecastQuery) -> [ReferenceRangeForecast] {
        return query.apply(store.list())
    }
}
