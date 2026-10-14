import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps batched rounding mappings by code.
    protocol BatchedRoundingMappingStore {
        func find(_ code: String) -> BatchedRoundingMapping?
        func save(_ item: BatchedRoundingMapping)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedRoundingMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedRoundingMappingStore: BatchedRoundingMappingStore {
        var items: [String: BatchedRoundingMapping]
        var order: [String]

        init(items: [String: BatchedRoundingMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedRoundingMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedRoundingMapping) {
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

        func list() -> [BatchedRoundingMapping] {
            var out: [BatchedRoundingMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedRoundingMappingStore() -> any BatchedRoundingMappingStore {
        return MemoryBatchedRoundingMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedRoundingMappingStore: BatchedRoundingMappingStore {
        var inner: MemoryBatchedRoundingMappingStore
        var cache: TTLCache<BatchedRoundingMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedRoundingMappingStore, cache: TTLCache<BatchedRoundingMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedRoundingMapping? {
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

        func save(_ item: BatchedRoundingMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedRoundingMapping] {
            return inner.list()
        }
    }

    static func newCachedBatchedRoundingMappingStore(_ inner: MemoryBatchedRoundingMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedRoundingMappingStore {
        return CachedBatchedRoundingMappingStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched rounding mappings. Empty fields match all.
    final class BatchedRoundingMappingQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedRoundingMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedRoundingMapping]) -> [BatchedRoundingMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedRoundingMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedRoundingMappings(_ store: any BatchedRoundingMappingStore, query: BatchedRoundingMappingQuery) -> [BatchedRoundingMapping] {
        return query.apply(store.list())
    }
}
