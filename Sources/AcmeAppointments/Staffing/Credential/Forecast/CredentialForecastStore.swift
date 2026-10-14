import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential forecasts by code.
    protocol CredentialForecastStore {
        func find(_ code: String) -> CredentialForecast?
        func save(_ item: CredentialForecast)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialForecastStore: CredentialForecastStore {
        var items: [String: CredentialForecast]
        var order: [String]

        init(items: [String: CredentialForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialForecast) {
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

        func list() -> [CredentialForecast] {
            var out: [CredentialForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialForecastStore() -> any CredentialForecastStore {
        return MemoryCredentialForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialForecastStore: CredentialForecastStore {
        var inner: MemoryCredentialForecastStore
        var cache: TTLCache<CredentialForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialForecastStore, cache: TTLCache<CredentialForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialForecast? {
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

        func save(_ item: CredentialForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialForecast] {
            return inner.list()
        }
    }

    static func newCachedCredentialForecastStore(_ inner: MemoryCredentialForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialForecastStore {
        return CachedCredentialForecastStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential forecasts. Empty fields match all.
    final class CredentialForecastQuery {
        var source: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minLimit: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialForecast) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CredentialForecast]) -> [CredentialForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialForecasts(_ store: any CredentialForecastStore, query: CredentialForecastQuery) -> [CredentialForecast] {
        return query.apply(store.list())
    }
}
