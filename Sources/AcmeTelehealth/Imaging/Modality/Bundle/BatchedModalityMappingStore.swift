import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps batched modality mappings by code.
    protocol BatchedModalityMappingStore {
        func find(_ code: String) -> BatchedModalityMapping?
        func save(_ item: BatchedModalityMapping)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedModalityMapping]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedModalityMappingStore: BatchedModalityMappingStore {
        var items: [String: BatchedModalityMapping]
        var order: [String]

        init(items: [String: BatchedModalityMapping], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedModalityMapping? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedModalityMapping) {
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

        func list() -> [BatchedModalityMapping] {
            var out: [BatchedModalityMapping] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedModalityMappingStore() -> any BatchedModalityMappingStore {
        return MemoryBatchedModalityMappingStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedModalityMappingStore: BatchedModalityMappingStore {
        var inner: MemoryBatchedModalityMappingStore
        var cache: TTLCache<BatchedModalityMapping>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedModalityMappingStore, cache: TTLCache<BatchedModalityMapping>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedModalityMapping? {
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

        func save(_ item: BatchedModalityMapping) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedModalityMapping] {
            return inner.list()
        }
    }

    static func newCachedBatchedModalityMappingStore(_ inner: MemoryBatchedModalityMappingStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedModalityMappingStore {
        return CachedBatchedModalityMappingStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched modality mappings. Empty fields match all.
    final class BatchedModalityMappingQuery {
        var name: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedModalityMapping) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedModalityMapping]) -> [BatchedModalityMapping] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedModalityMapping) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedModalityMappings(_ store: any BatchedModalityMappingStore, query: BatchedModalityMappingQuery) -> [BatchedModalityMapping] {
        return query.apply(store.list())
    }
}
