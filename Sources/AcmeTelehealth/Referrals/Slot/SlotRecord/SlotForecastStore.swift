import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot forecasts by code.
    protocol SlotForecastStore {
        func find(_ code: String) -> SlotForecast?
        func save(_ item: SlotForecast)
        func remove(_ code: String) -> Bool
        func list() -> [SlotForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotForecastStore: SlotForecastStore {
        var items: [String: SlotForecast]
        var order: [String]

        init(items: [String: SlotForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotForecast) {
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

        func list() -> [SlotForecast] {
            var out: [SlotForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotForecastStore() -> any SlotForecastStore {
        return MemorySlotForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotForecastStore: SlotForecastStore {
        var inner: MemorySlotForecastStore
        var cache: TTLCache<SlotForecast>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotForecastStore, cache: TTLCache<SlotForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotForecast? {
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

        func save(_ item: SlotForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotForecast] {
            return inner.list()
        }
    }

    static func newCachedSlotForecastStore(_ inner: MemorySlotForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotForecastStore {
        return CachedSlotForecastStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot forecasts. Empty fields match all.
    final class SlotForecastQuery {
        var name: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCost: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotForecast) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SlotForecast]) -> [SlotForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotForecasts(_ store: any SlotForecastStore, query: SlotForecastQuery) -> [SlotForecast] {
        return query.apply(store.list())
    }
}
