import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps global closure forecasts by code.
    protocol GlobalClosureForecastStore {
        func find(_ code: String) -> GlobalClosureForecast?
        func save(_ item: GlobalClosureForecast)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalClosureForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalClosureForecastStore: GlobalClosureForecastStore {
        var items: [String: GlobalClosureForecast]
        var order: [String]

        init(items: [String: GlobalClosureForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalClosureForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalClosureForecast) {
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

        func list() -> [GlobalClosureForecast] {
            var out: [GlobalClosureForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalClosureForecastStore() -> any GlobalClosureForecastStore {
        return MemoryGlobalClosureForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalClosureForecastStore: GlobalClosureForecastStore {
        var inner: MemoryGlobalClosureForecastStore
        var cache: TTLCache<GlobalClosureForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalClosureForecastStore, cache: TTLCache<GlobalClosureForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalClosureForecast? {
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

        func save(_ item: GlobalClosureForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalClosureForecast] {
            return inner.list()
        }
    }

    static func newCachedGlobalClosureForecastStore(_ inner: MemoryGlobalClosureForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalClosureForecastStore {
        return CachedGlobalClosureForecastStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global closure forecasts. Empty fields match all.
    final class GlobalClosureForecastQuery {
        var title: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalClosureForecast) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalClosureForecast]) -> [GlobalClosureForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalClosureForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalClosureForecasts(_ store: any GlobalClosureForecastStore, query: GlobalClosureForecastQuery) -> [GlobalClosureForecast] {
        return query.apply(store.list())
    }
}
