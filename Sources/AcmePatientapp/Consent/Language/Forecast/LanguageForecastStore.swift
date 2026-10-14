import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language forecasts by code.
    protocol LanguageForecastStore {
        func find(_ code: String) -> LanguageForecast?
        func save(_ item: LanguageForecast)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageForecastStore: LanguageForecastStore {
        var items: [String: LanguageForecast]
        var order: [String]

        init(items: [String: LanguageForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageForecast) {
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

        func list() -> [LanguageForecast] {
            var out: [LanguageForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageForecastStore() -> any LanguageForecastStore {
        return MemoryLanguageForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageForecastStore: LanguageForecastStore {
        var inner: MemoryLanguageForecastStore
        var cache: TTLCache<LanguageForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageForecastStore, cache: TTLCache<LanguageForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageForecast? {
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

        func save(_ item: LanguageForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageForecast] {
            return inner.list()
        }
    }

    static func newCachedLanguageForecastStore(_ inner: MemoryLanguageForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageForecastStore {
        return CachedLanguageForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language forecasts. Empty fields match all.
    final class LanguageForecastQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LanguageForecast) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LanguageForecast]) -> [LanguageForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageForecasts(_ store: any LanguageForecastStore, query: LanguageForecastQuery) -> [LanguageForecast] {
        return query.apply(store.list())
    }
}
