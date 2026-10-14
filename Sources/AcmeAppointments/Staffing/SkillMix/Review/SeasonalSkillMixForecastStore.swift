import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps seasonal skill mix forecasts by code.
    protocol SeasonalSkillMixForecastStore {
        func find(_ code: String) -> SeasonalSkillMixForecast?
        func save(_ item: SeasonalSkillMixForecast)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalSkillMixForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalSkillMixForecastStore: SeasonalSkillMixForecastStore {
        var items: [String: SeasonalSkillMixForecast]
        var order: [String]

        init(items: [String: SeasonalSkillMixForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalSkillMixForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalSkillMixForecast) {
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

        func list() -> [SeasonalSkillMixForecast] {
            var out: [SeasonalSkillMixForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalSkillMixForecastStore() -> any SeasonalSkillMixForecastStore {
        return MemorySeasonalSkillMixForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalSkillMixForecastStore: SeasonalSkillMixForecastStore {
        var inner: MemorySeasonalSkillMixForecastStore
        var cache: TTLCache<SeasonalSkillMixForecast>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalSkillMixForecastStore, cache: TTLCache<SeasonalSkillMixForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalSkillMixForecast? {
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

        func save(_ item: SeasonalSkillMixForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalSkillMixForecast] {
            return inner.list()
        }
    }

    static func newCachedSeasonalSkillMixForecastStore(_ inner: MemorySeasonalSkillMixForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalSkillMixForecastStore {
        return CachedSeasonalSkillMixForecastStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal skill mix forecasts. Empty fields match all.
    final class SeasonalSkillMixForecastQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalSkillMixForecast) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalSkillMixForecast]) -> [SeasonalSkillMixForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalSkillMixForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalSkillMixForecasts(_ store: any SeasonalSkillMixForecastStore, query: SeasonalSkillMixForecastQuery) -> [SeasonalSkillMixForecast] {
        return query.apply(store.list())
    }
}
