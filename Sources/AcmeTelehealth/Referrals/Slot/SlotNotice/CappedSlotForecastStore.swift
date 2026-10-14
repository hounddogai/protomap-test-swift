import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps capped slot forecasts by code.
    protocol CappedSlotForecastStore {
        func find(_ code: String) -> CappedSlotForecast?
        func save(_ item: CappedSlotForecast)
        func remove(_ code: String) -> Bool
        func list() -> [CappedSlotForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedSlotForecastStore: CappedSlotForecastStore {
        var items: [String: CappedSlotForecast]
        var order: [String]

        init(items: [String: CappedSlotForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedSlotForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedSlotForecast) {
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

        func list() -> [CappedSlotForecast] {
            var out: [CappedSlotForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedSlotForecastStore() -> any CappedSlotForecastStore {
        return MemoryCappedSlotForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedSlotForecastStore: CappedSlotForecastStore {
        var inner: MemoryCappedSlotForecastStore
        var cache: TTLCache<CappedSlotForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedSlotForecastStore, cache: TTLCache<CappedSlotForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedSlotForecast? {
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

        func save(_ item: CappedSlotForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedSlotForecast] {
            return inner.list()
        }
    }

    static func newCachedCappedSlotForecastStore(_ inner: MemoryCappedSlotForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedSlotForecastStore {
        return CachedCappedSlotForecastStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped slot forecasts. Empty fields match all.
    final class CappedSlotForecastQuery {
        var name: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minAmount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedSlotForecast) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedSlotForecast]) -> [CappedSlotForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedSlotForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedSlotForecasts(_ store: any CappedSlotForecastStore, query: CappedSlotForecastQuery) -> [CappedSlotForecast] {
        return query.apply(store.list())
    }
}
