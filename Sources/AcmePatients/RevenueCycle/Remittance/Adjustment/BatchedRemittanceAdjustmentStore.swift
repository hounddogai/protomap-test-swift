import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched remittance adjustments by code.
    protocol BatchedRemittanceAdjustmentStore {
        func find(_ code: String) -> BatchedRemittanceAdjustment?
        func save(_ item: BatchedRemittanceAdjustment)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedRemittanceAdjustment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedRemittanceAdjustmentStore: BatchedRemittanceAdjustmentStore {
        var items: [String: BatchedRemittanceAdjustment]
        var order: [String]

        init(items: [String: BatchedRemittanceAdjustment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedRemittanceAdjustment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedRemittanceAdjustment) {
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

        func list() -> [BatchedRemittanceAdjustment] {
            var out: [BatchedRemittanceAdjustment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedRemittanceAdjustmentStore() -> any BatchedRemittanceAdjustmentStore {
        return MemoryBatchedRemittanceAdjustmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedRemittanceAdjustmentStore: BatchedRemittanceAdjustmentStore {
        var inner: MemoryBatchedRemittanceAdjustmentStore
        var cache: TTLCache<BatchedRemittanceAdjustment>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedRemittanceAdjustmentStore, cache: TTLCache<BatchedRemittanceAdjustment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedRemittanceAdjustment? {
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

        func save(_ item: BatchedRemittanceAdjustment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedRemittanceAdjustment] {
            return inner.list()
        }
    }

    static func newCachedBatchedRemittanceAdjustmentStore(_ inner: MemoryBatchedRemittanceAdjustmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedRemittanceAdjustmentStore {
        return CachedBatchedRemittanceAdjustmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched remittance adjustments. Empty fields match all.
    final class BatchedRemittanceAdjustmentQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedRemittanceAdjustment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedRemittanceAdjustment]) -> [BatchedRemittanceAdjustment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedRemittanceAdjustment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedRemittanceAdjustments(_ store: any BatchedRemittanceAdjustmentStore, query: BatchedRemittanceAdjustmentQuery) -> [BatchedRemittanceAdjustment] {
        return query.apply(store.list())
    }
}
