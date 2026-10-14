import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps batched inventory baselines by code.
    protocol BatchedInventoryBaselineStore {
        func find(_ code: String) -> BatchedInventoryBaseline?
        func save(_ item: BatchedInventoryBaseline)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedInventoryBaseline]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedInventoryBaselineStore: BatchedInventoryBaselineStore {
        var items: [String: BatchedInventoryBaseline]
        var order: [String]

        init(items: [String: BatchedInventoryBaseline], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedInventoryBaseline? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedInventoryBaseline) {
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

        func list() -> [BatchedInventoryBaseline] {
            var out: [BatchedInventoryBaseline] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedInventoryBaselineStore() -> any BatchedInventoryBaselineStore {
        return MemoryBatchedInventoryBaselineStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedInventoryBaselineStore: BatchedInventoryBaselineStore {
        var inner: MemoryBatchedInventoryBaselineStore
        var cache: TTLCache<BatchedInventoryBaseline>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedInventoryBaselineStore, cache: TTLCache<BatchedInventoryBaseline>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedInventoryBaseline? {
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

        func save(_ item: BatchedInventoryBaseline) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedInventoryBaseline] {
            return inner.list()
        }
    }

    static func newCachedBatchedInventoryBaselineStore(_ inner: MemoryBatchedInventoryBaselineStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedInventoryBaselineStore {
        return CachedBatchedInventoryBaselineStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched inventory baselines. Empty fields match all.
    final class BatchedInventoryBaselineQuery {
        var label: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedInventoryBaseline) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedInventoryBaseline]) -> [BatchedInventoryBaseline] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedInventoryBaseline) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedInventoryBaselines(_ store: any BatchedInventoryBaselineStore, query: BatchedInventoryBaselineQuery) -> [BatchedInventoryBaseline] {
        return query.apply(store.list())
    }
}
