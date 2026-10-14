import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps strict skill mix forecasts by code.
    protocol StrictSkillMixForecastStore {
        func find(_ code: String) -> StrictSkillMixForecast?
        func save(_ item: StrictSkillMixForecast)
        func remove(_ code: String) -> Bool
        func list() -> [StrictSkillMixForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictSkillMixForecastStore: StrictSkillMixForecastStore {
        var items: [String: StrictSkillMixForecast]
        var order: [String]

        init(items: [String: StrictSkillMixForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictSkillMixForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictSkillMixForecast) {
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

        func list() -> [StrictSkillMixForecast] {
            var out: [StrictSkillMixForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictSkillMixForecastStore() -> any StrictSkillMixForecastStore {
        return MemoryStrictSkillMixForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictSkillMixForecastStore: StrictSkillMixForecastStore {
        var inner: MemoryStrictSkillMixForecastStore
        var cache: TTLCache<StrictSkillMixForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictSkillMixForecastStore, cache: TTLCache<StrictSkillMixForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictSkillMixForecast? {
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

        func save(_ item: StrictSkillMixForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictSkillMixForecast] {
            return inner.list()
        }
    }

    static func newCachedStrictSkillMixForecastStore(_ inner: MemoryStrictSkillMixForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictSkillMixForecastStore {
        return CachedStrictSkillMixForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict skill mix forecasts. Empty fields match all.
    final class StrictSkillMixForecastQuery {
        var ward: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictSkillMixForecast) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictSkillMixForecast]) -> [StrictSkillMixForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictSkillMixForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictSkillMixForecasts(_ store: any StrictSkillMixForecastStore, query: StrictSkillMixForecastQuery) -> [StrictSkillMixForecast] {
        return query.apply(store.list())
    }
}
