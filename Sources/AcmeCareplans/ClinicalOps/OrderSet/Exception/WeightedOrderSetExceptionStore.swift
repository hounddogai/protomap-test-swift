import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps weighted order set exceptions by code.
    protocol WeightedOrderSetExceptionStore {
        func find(_ code: String) -> WeightedOrderSetException?
        func save(_ item: WeightedOrderSetException)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedOrderSetException]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedOrderSetExceptionStore: WeightedOrderSetExceptionStore {
        var items: [String: WeightedOrderSetException]
        var order: [String]

        init(items: [String: WeightedOrderSetException], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedOrderSetException? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedOrderSetException) {
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

        func list() -> [WeightedOrderSetException] {
            var out: [WeightedOrderSetException] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedOrderSetExceptionStore() -> any WeightedOrderSetExceptionStore {
        return MemoryWeightedOrderSetExceptionStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedOrderSetExceptionStore: WeightedOrderSetExceptionStore {
        var inner: MemoryWeightedOrderSetExceptionStore
        var cache: TTLCache<WeightedOrderSetException>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedOrderSetExceptionStore, cache: TTLCache<WeightedOrderSetException>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedOrderSetException? {
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

        func save(_ item: WeightedOrderSetException) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedOrderSetException] {
            return inner.list()
        }
    }

    static func newCachedWeightedOrderSetExceptionStore(_ inner: MemoryWeightedOrderSetExceptionStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedOrderSetExceptionStore {
        return CachedWeightedOrderSetExceptionStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted order set exceptions. Empty fields match all.
    final class WeightedOrderSetExceptionQuery {
        var unit: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedOrderSetException) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [WeightedOrderSetException]) -> [WeightedOrderSetException] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedOrderSetException) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedOrderSetExceptions(_ store: any WeightedOrderSetExceptionStore, query: WeightedOrderSetExceptionQuery) -> [WeightedOrderSetException] {
        return query.apply(store.list())
    }
}
