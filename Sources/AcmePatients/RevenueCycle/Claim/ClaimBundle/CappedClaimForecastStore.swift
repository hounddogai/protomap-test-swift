import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps capped claim forecasts by code.
    protocol CappedClaimForecastStore {
        func find(_ code: String) -> CappedClaimForecast?
        func save(_ item: CappedClaimForecast)
        func remove(_ code: String) -> Bool
        func list() -> [CappedClaimForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedClaimForecastStore: CappedClaimForecastStore {
        var items: [String: CappedClaimForecast]
        var order: [String]

        init(items: [String: CappedClaimForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedClaimForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedClaimForecast) {
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

        func list() -> [CappedClaimForecast] {
            var out: [CappedClaimForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedClaimForecastStore() -> any CappedClaimForecastStore {
        return MemoryCappedClaimForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedClaimForecastStore: CappedClaimForecastStore {
        var inner: MemoryCappedClaimForecastStore
        var cache: TTLCache<CappedClaimForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedClaimForecastStore, cache: TTLCache<CappedClaimForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedClaimForecast? {
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

        func save(_ item: CappedClaimForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedClaimForecast] {
            return inner.list()
        }
    }

    static func newCachedCappedClaimForecastStore(_ inner: MemoryCappedClaimForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedClaimForecastStore {
        return CachedCappedClaimForecastStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped claim forecasts. Empty fields match all.
    final class CappedClaimForecastQuery {
        var channel: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minRevision: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedClaimForecast) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedClaimForecast]) -> [CappedClaimForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedClaimForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedClaimForecasts(_ store: any CappedClaimForecastStore, query: CappedClaimForecastQuery) -> [CappedClaimForecast] {
        return query.apply(store.list())
    }
}
