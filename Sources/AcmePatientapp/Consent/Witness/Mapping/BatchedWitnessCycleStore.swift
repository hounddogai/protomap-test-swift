import AcmePlatform
import Foundation

extension Consent {
    /// Keeps batched witness cycles by code.
    protocol BatchedWitnessCycleStore {
        func find(_ code: String) -> BatchedWitnessCycle?
        func save(_ item: BatchedWitnessCycle)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedWitnessCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedWitnessCycleStore: BatchedWitnessCycleStore {
        var items: [String: BatchedWitnessCycle]
        var order: [String]

        init(items: [String: BatchedWitnessCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedWitnessCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedWitnessCycle) {
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

        func list() -> [BatchedWitnessCycle] {
            var out: [BatchedWitnessCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedWitnessCycleStore() -> any BatchedWitnessCycleStore {
        return MemoryBatchedWitnessCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedWitnessCycleStore: BatchedWitnessCycleStore {
        var inner: MemoryBatchedWitnessCycleStore
        var cache: TTLCache<BatchedWitnessCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedWitnessCycleStore, cache: TTLCache<BatchedWitnessCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedWitnessCycle? {
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

        func save(_ item: BatchedWitnessCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedWitnessCycle] {
            return inner.list()
        }
    }

    static func newCachedBatchedWitnessCycleStore(_ inner: MemoryBatchedWitnessCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedWitnessCycleStore {
        return CachedBatchedWitnessCycleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched witness cycles. Empty fields match all.
    final class BatchedWitnessCycleQuery {
        var name: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minBudget: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedWitnessCycle) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedWitnessCycle]) -> [BatchedWitnessCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedWitnessCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedWitnessCycles(_ store: any BatchedWitnessCycleStore, query: BatchedWitnessCycleQuery) -> [BatchedWitnessCycle] {
        return query.apply(store.list())
    }
}
