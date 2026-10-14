import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped statement forecasts by code.
    protocol CappedStatementForecastStore {
        func find(_ code: String) -> CappedStatementForecast?
        func save(_ item: CappedStatementForecast)
        func remove(_ code: String) -> Bool
        func list() -> [CappedStatementForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedStatementForecastStore: CappedStatementForecastStore {
        var items: [String: CappedStatementForecast]
        var order: [String]

        init(items: [String: CappedStatementForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedStatementForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedStatementForecast) {
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

        func list() -> [CappedStatementForecast] {
            var out: [CappedStatementForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedStatementForecastStore() -> any CappedStatementForecastStore {
        return MemoryCappedStatementForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedStatementForecastStore: CappedStatementForecastStore {
        var inner: MemoryCappedStatementForecastStore
        var cache: TTLCache<CappedStatementForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedStatementForecastStore, cache: TTLCache<CappedStatementForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedStatementForecast? {
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

        func save(_ item: CappedStatementForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedStatementForecast] {
            return inner.list()
        }
    }

    static func newCachedCappedStatementForecastStore(_ inner: MemoryCappedStatementForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedStatementForecastStore {
        return CachedCappedStatementForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped statement forecasts. Empty fields match all.
    final class CappedStatementForecastQuery {
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

        func matches(_ item: CappedStatementForecast) -> Bool {
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

        func apply(_ items: [CappedStatementForecast]) -> [CappedStatementForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedStatementForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedStatementForecasts(_ store: any CappedStatementForecastStore, query: CappedStatementForecastQuery) -> [CappedStatementForecast] {
        return query.apply(store.list())
    }
}
