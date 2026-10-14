import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task batches by code.
    protocol TaskBatchStore {
        func find(_ code: String) -> TaskBatch?
        func save(_ item: TaskBatch)
        func remove(_ code: String) -> Bool
        func list() -> [TaskBatch]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskBatchStore: TaskBatchStore {
        var items: [String: TaskBatch]
        var order: [String]

        init(items: [String: TaskBatch], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskBatch? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskBatch) {
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

        func list() -> [TaskBatch] {
            var out: [TaskBatch] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskBatchStore() -> any TaskBatchStore {
        return MemoryTaskBatchStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskBatchStore: TaskBatchStore {
        var inner: MemoryTaskBatchStore
        var cache: TTLCache<TaskBatch>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskBatchStore, cache: TTLCache<TaskBatch>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskBatch? {
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

        func save(_ item: TaskBatch) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskBatch] {
            return inner.list()
        }
    }

    static func newCachedTaskBatchStore(_ inner: MemoryTaskBatchStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskBatchStore {
        return CachedTaskBatchStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task batches. Empty fields match all.
    final class TaskBatchQuery {
        var region: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskBatch) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskBatch]) -> [TaskBatch] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskBatch) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskBatches(_ store: any TaskBatchStore, query: TaskBatchQuery) -> [TaskBatch] {
        return query.apply(store.list())
    }
}
