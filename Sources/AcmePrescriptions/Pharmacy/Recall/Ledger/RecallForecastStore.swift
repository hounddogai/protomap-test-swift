import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall forecasts by code.
    protocol RecallForecastStore {
        func find(_ code: String) -> RecallForecast?
        func save(_ item: RecallForecast)
        func remove(_ code: String) -> Bool
        func list() -> [RecallForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallForecastStore: RecallForecastStore {
        var items: [String: RecallForecast]
        var order: [String]

        init(items: [String: RecallForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallForecast) {
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

        func list() -> [RecallForecast] {
            var out: [RecallForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallForecastStore() -> any RecallForecastStore {
        return MemoryRecallForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallForecastStore: RecallForecastStore {
        var inner: MemoryRecallForecastStore
        var cache: TTLCache<RecallForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallForecastStore, cache: TTLCache<RecallForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallForecast? {
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

        func save(_ item: RecallForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallForecast] {
            return inner.list()
        }
    }

    static func newCachedRecallForecastStore(_ inner: MemoryRecallForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallForecastStore {
        return CachedRecallForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall forecasts. Empty fields match all.
    final class RecallForecastQuery {
        var title: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minSequence: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallForecast) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RecallForecast]) -> [RecallForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallForecasts(_ store: any RecallForecastStore, query: RecallForecastQuery) -> [RecallForecast] {
        return query.apply(store.list())
    }
}
