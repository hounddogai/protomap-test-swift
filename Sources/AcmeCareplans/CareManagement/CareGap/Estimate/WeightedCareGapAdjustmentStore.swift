import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted care gap adjustments by code.
    protocol WeightedCareGapAdjustmentStore {
        func find(_ code: String) -> WeightedCareGapAdjustment?
        func save(_ item: WeightedCareGapAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedCareGapAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedCareGapAdjustmentStore: WeightedCareGapAdjustmentStore {
        var items: [String: WeightedCareGapAdjustment]
        var order: [String]

        init(items: [String: WeightedCareGapAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedCareGapAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedCareGapAdjustment) {
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

        func list() -> [WeightedCareGapAdjustment] {
            var out: [WeightedCareGapAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedCareGapAdjustmentStore() -> any WeightedCareGapAdjustmentStore {
        return MemoryWeightedCareGapAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedCareGapAdjustmentStore: WeightedCareGapAdjustmentStore {
        var inner: MemoryWeightedCareGapAdjustmentStore
        var cache: TTLCache<WeightedCareGapAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedCareGapAdjustmentStore, cache: TTLCache<WeightedCareGapAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedCareGapAdjustment? {
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

        func save(_ item: WeightedCareGapAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedCareGapAdjustment] {
            return inner.list()
        }
    }

    static func newCachedWeightedCareGapAdjustmentStore(_ inner: MemoryWeightedCareGapAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedCareGapAdjustmentStore {
        return CachedWeightedCareGapAdjustmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted care gap adjustments. Empty fields match all.
    final class WeightedCareGapAdjustmentQuery {
        var unit: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedCareGapAdjustment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedCareGapAdjustment]) -> [WeightedCareGapAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedCareGapAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedCareGapAdjustments(_ store: any WeightedCareGapAdjustmentStore, query: WeightedCareGapAdjustmentQuery) -> [WeightedCareGapAdjustment] {
        return query.apply(store.list())
    }
}
