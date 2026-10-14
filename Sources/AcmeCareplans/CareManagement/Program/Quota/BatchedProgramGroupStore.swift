import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched program groups by code.
    protocol BatchedProgramGroupStore {
        func find(_ code: String) -> BatchedProgramGroup?
        func save(_ item: BatchedProgramGroup)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedProgramGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedProgramGroupStore: BatchedProgramGroupStore {
        var items: [String: BatchedProgramGroup]
        var order: [String]

        init(items: [String: BatchedProgramGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedProgramGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedProgramGroup) {
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

        func list() -> [BatchedProgramGroup] {
            var out: [BatchedProgramGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedProgramGroupStore() -> any BatchedProgramGroupStore {
        return MemoryBatchedProgramGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedProgramGroupStore: BatchedProgramGroupStore {
        var inner: MemoryBatchedProgramGroupStore
        var cache: TTLCache<BatchedProgramGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedProgramGroupStore, cache: TTLCache<BatchedProgramGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedProgramGroup? {
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

        func save(_ item: BatchedProgramGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedProgramGroup] {
            return inner.list()
        }
    }

    static func newCachedBatchedProgramGroupStore(_ inner: MemoryBatchedProgramGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedProgramGroupStore {
        return CachedBatchedProgramGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched program groups. Empty fields match all.
    final class BatchedProgramGroupQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedProgramGroup) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedProgramGroup]) -> [BatchedProgramGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedProgramGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedProgramGroups(_ store: any BatchedProgramGroupStore, query: BatchedProgramGroupQuery) -> [BatchedProgramGroup] {
        return query.apply(store.list())
    }
}
