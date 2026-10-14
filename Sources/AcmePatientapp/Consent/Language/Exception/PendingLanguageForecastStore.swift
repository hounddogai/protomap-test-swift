import AcmePlatform
import Foundation

extension Consent {
    /// Keeps pending language forecasts by code.
    protocol PendingLanguageForecastStore {
        func find(_ code: String) -> PendingLanguageForecast?
        func save(_ item: PendingLanguageForecast)
        func remove(_ code: String) -> Bool
        func list() -> [PendingLanguageForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingLanguageForecastStore: PendingLanguageForecastStore {
        var items: [String: PendingLanguageForecast]
        var order: [String]

        init(items: [String: PendingLanguageForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingLanguageForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingLanguageForecast) {
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

        func list() -> [PendingLanguageForecast] {
            var out: [PendingLanguageForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingLanguageForecastStore() -> any PendingLanguageForecastStore {
        return MemoryPendingLanguageForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingLanguageForecastStore: PendingLanguageForecastStore {
        var inner: MemoryPendingLanguageForecastStore
        var cache: TTLCache<PendingLanguageForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingLanguageForecastStore, cache: TTLCache<PendingLanguageForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingLanguageForecast? {
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

        func save(_ item: PendingLanguageForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingLanguageForecast] {
            return inner.list()
        }
    }

    static func newCachedPendingLanguageForecastStore(_ inner: MemoryPendingLanguageForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingLanguageForecastStore {
        return CachedPendingLanguageForecastStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending language forecasts. Empty fields match all.
    final class PendingLanguageForecastQuery {
        var country: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingLanguageForecast) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [PendingLanguageForecast]) -> [PendingLanguageForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingLanguageForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingLanguageForecasts(_ store: any PendingLanguageForecastStore, query: PendingLanguageForecastQuery) -> [PendingLanguageForecast] {
        return query.apply(store.list())
    }
}
