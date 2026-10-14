import AcmePlatform
import Foundation

extension Consent {
    /// Keeps batched witness forecasts by code.
    protocol BatchedWitnessForecastStore {
        func find(_ code: String) -> BatchedWitnessForecast?
        func save(_ item: BatchedWitnessForecast)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedWitnessForecast]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedWitnessForecastStore: BatchedWitnessForecastStore {
        var items: [String: BatchedWitnessForecast]
        var order: [String]

        init(items: [String: BatchedWitnessForecast], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedWitnessForecast? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedWitnessForecast) {
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

        func list() -> [BatchedWitnessForecast] {
            var out: [BatchedWitnessForecast] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedWitnessForecastStore() -> any BatchedWitnessForecastStore {
        return MemoryBatchedWitnessForecastStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedWitnessForecastStore: BatchedWitnessForecastStore {
        var inner: MemoryBatchedWitnessForecastStore
        var cache: TTLCache<BatchedWitnessForecast>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedWitnessForecastStore, cache: TTLCache<BatchedWitnessForecast>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedWitnessForecast? {
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

        func save(_ item: BatchedWitnessForecast) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedWitnessForecast] {
            return inner.list()
        }
    }

    static func newCachedBatchedWitnessForecastStore(_ inner: MemoryBatchedWitnessForecastStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedWitnessForecastStore {
        return CachedBatchedWitnessForecastStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched witness forecasts. Empty fields match all.
    final class BatchedWitnessForecastQuery {
        var title: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVersion: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedWitnessForecast) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedWitnessForecast]) -> [BatchedWitnessForecast] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedWitnessForecast) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedWitnessForecasts(_ store: any BatchedWitnessForecastStore, query: BatchedWitnessForecastQuery) -> [BatchedWitnessForecast] {
        return query.apply(store.list())
    }
}
