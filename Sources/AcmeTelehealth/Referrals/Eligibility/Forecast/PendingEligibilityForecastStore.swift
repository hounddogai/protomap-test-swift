import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending eligibility forecasts by code.
    protocol PendingEligibilityForecastStore {
        func find(_ code: String) -> PendingEligibilityForecast?
        func save(_ item: PendingEligibilityForecast)
        func remove(_ code: String) -> Bool
        func list() -> [PendingEligibilityForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingEligibilityForecastStore: PendingEligibilityForecastStore {
        var items: [String: PendingEligibilityForecast]
        var order: [String]

        init(items: [String: PendingEligibilityForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingEligibilityForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingEligibilityForecast) {
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

        func list() -> [PendingEligibilityForecast] {
            var out: [PendingEligibilityForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingEligibilityForecastStore() -> any PendingEligibilityForecastStore {
        return MemoryPendingEligibilityForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingEligibilityForecastStore: PendingEligibilityForecastStore {
        var inner: MemoryPendingEligibilityForecastStore
        var cache: TTLCache<PendingEligibilityForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingEligibilityForecastStore, cache: TTLCache<PendingEligibilityForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingEligibilityForecast? {
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

        func save(_ item: PendingEligibilityForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingEligibilityForecast] {
            return inner.list()
        }
    }

    static func newCachedPendingEligibilityForecastStore(_ inner: MemoryPendingEligibilityForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingEligibilityForecastStore {
        return CachedPendingEligibilityForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending eligibility forecasts. Empty fields match all.
    final class PendingEligibilityForecastQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingEligibilityForecast) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingEligibilityForecast]) -> [PendingEligibilityForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingEligibilityForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingEligibilityForecasts(_ store: any PendingEligibilityForecastStore, query: PendingEligibilityForecastQuery) -> [PendingEligibilityForecast] {
        return query.apply(store.list())
    }
}
