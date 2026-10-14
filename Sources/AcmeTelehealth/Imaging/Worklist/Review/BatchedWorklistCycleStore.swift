import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps batched worklist cycles by code.
    protocol BatchedWorklistCycleStore {
        func find(_ code: String) -> BatchedWorklistCycle?
        func save(_ item: BatchedWorklistCycle)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedWorklistCycle]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedWorklistCycleStore: BatchedWorklistCycleStore {
        var items: [String: BatchedWorklistCycle]
        var order: [String]

        init(items: [String: BatchedWorklistCycle], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedWorklistCycle? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedWorklistCycle) {
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

        func list() -> [BatchedWorklistCycle] {
            var out: [BatchedWorklistCycle] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedWorklistCycleStore() -> any BatchedWorklistCycleStore {
        return MemoryBatchedWorklistCycleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedWorklistCycleStore: BatchedWorklistCycleStore {
        var inner: MemoryBatchedWorklistCycleStore
        var cache: TTLCache<BatchedWorklistCycle>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedWorklistCycleStore, cache: TTLCache<BatchedWorklistCycle>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedWorklistCycle? {
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

        func save(_ item: BatchedWorklistCycle) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedWorklistCycle] {
            return inner.list()
        }
    }

    static func newCachedBatchedWorklistCycleStore(_ inner: MemoryBatchedWorklistCycleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedWorklistCycleStore {
        return CachedBatchedWorklistCycleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched worklist cycles. Empty fields match all.
    final class BatchedWorklistCycleQuery {
        var facility: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedWorklistCycle) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedWorklistCycle]) -> [BatchedWorklistCycle] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedWorklistCycle) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedWorklistCycles(_ store: any BatchedWorklistCycleStore, query: BatchedWorklistCycleQuery) -> [BatchedWorklistCycle] {
        return query.apply(store.list())
    }
}
