import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global acuity plan forecasts by code.
    protocol GlobalAcuityPlanForecastStore {
        func find(_ code: String) -> GlobalAcuityPlanForecast?
        func save(_ item: GlobalAcuityPlanForecast)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalAcuityPlanForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalAcuityPlanForecastStore: GlobalAcuityPlanForecastStore {
        var items: [String: GlobalAcuityPlanForecast]
        var order: [String]

        init(items: [String: GlobalAcuityPlanForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalAcuityPlanForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalAcuityPlanForecast) {
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

        func list() -> [GlobalAcuityPlanForecast] {
            var out: [GlobalAcuityPlanForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalAcuityPlanForecastStore() -> any GlobalAcuityPlanForecastStore {
        return MemoryGlobalAcuityPlanForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalAcuityPlanForecastStore: GlobalAcuityPlanForecastStore {
        var inner: MemoryGlobalAcuityPlanForecastStore
        var cache: TTLCache<GlobalAcuityPlanForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalAcuityPlanForecastStore, cache: TTLCache<GlobalAcuityPlanForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalAcuityPlanForecast? {
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

        func save(_ item: GlobalAcuityPlanForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalAcuityPlanForecast] {
            return inner.list()
        }
    }

    static func newCachedGlobalAcuityPlanForecastStore(_ inner: MemoryGlobalAcuityPlanForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalAcuityPlanForecastStore {
        return CachedGlobalAcuityPlanForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global acuity plan forecasts. Empty fields match all.
    final class GlobalAcuityPlanForecastQuery {
        var locale: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalAcuityPlanForecast) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalAcuityPlanForecast]) -> [GlobalAcuityPlanForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalAcuityPlanForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalAcuityPlanForecasts(_ store: any GlobalAcuityPlanForecastStore, query: GlobalAcuityPlanForecastQuery) -> [GlobalAcuityPlanForecast] {
        return query.apply(store.list())
    }
}
