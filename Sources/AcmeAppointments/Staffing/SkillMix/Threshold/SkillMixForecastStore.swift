import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix forecasts by code.
    protocol SkillMixForecastStore {
        func find(_ code: String) -> SkillMixForecast?
        func save(_ item: SkillMixForecast)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixForecastStore: SkillMixForecastStore {
        var items: [String: SkillMixForecast]
        var order: [String]

        init(items: [String: SkillMixForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixForecast) {
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

        func list() -> [SkillMixForecast] {
            var out: [SkillMixForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixForecastStore() -> any SkillMixForecastStore {
        return MemorySkillMixForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixForecastStore: SkillMixForecastStore {
        var inner: MemorySkillMixForecastStore
        var cache: TTLCache<SkillMixForecast>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixForecastStore, cache: TTLCache<SkillMixForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixForecast? {
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

        func save(_ item: SkillMixForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixForecast] {
            return inner.list()
        }
    }

    static func newCachedSkillMixForecastStore(_ inner: MemorySkillMixForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixForecastStore {
        return CachedSkillMixForecastStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix forecasts. Empty fields match all.
    final class SkillMixForecastQuery {
        var ward: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixForecast) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixForecast]) -> [SkillMixForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixForecasts(_ store: any SkillMixForecastStore, query: SkillMixForecastQuery) -> [SkillMixForecast] {
        return query.apply(store.list())
    }
}
