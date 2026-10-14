import AcmePlatform
import Foundation

extension Consent {
    /// Keeps batched witness adjustments by code.
    protocol BatchedWitnessAdjustmentStore {
        func find(_ code: String) -> BatchedWitnessAdjustment?
        func save(_ item: BatchedWitnessAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedWitnessAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedWitnessAdjustmentStore: BatchedWitnessAdjustmentStore {
        var items: [String: BatchedWitnessAdjustment]
        var order: [String]

        init(items: [String: BatchedWitnessAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedWitnessAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedWitnessAdjustment) {
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

        func list() -> [BatchedWitnessAdjustment] {
            var out: [BatchedWitnessAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedWitnessAdjustmentStore() -> any BatchedWitnessAdjustmentStore {
        return MemoryBatchedWitnessAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedWitnessAdjustmentStore: BatchedWitnessAdjustmentStore {
        var inner: MemoryBatchedWitnessAdjustmentStore
        var cache: TTLCache<BatchedWitnessAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedWitnessAdjustmentStore, cache: TTLCache<BatchedWitnessAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedWitnessAdjustment? {
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

        func save(_ item: BatchedWitnessAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedWitnessAdjustment] {
            return inner.list()
        }
    }

    static func newCachedBatchedWitnessAdjustmentStore(_ inner: MemoryBatchedWitnessAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedWitnessAdjustmentStore {
        return CachedBatchedWitnessAdjustmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched witness adjustments. Empty fields match all.
    final class BatchedWitnessAdjustmentQuery {
        var unit: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedWitnessAdjustment) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedWitnessAdjustment]) -> [BatchedWitnessAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedWitnessAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedWitnessAdjustments(_ store: any BatchedWitnessAdjustmentStore, query: BatchedWitnessAdjustmentQuery) -> [BatchedWitnessAdjustment] {
        return query.apply(store.list())
    }
}
