import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched claim assignments by code.
    protocol BatchedClaimAssignmentStore {
        func find(_ code: String) -> BatchedClaimAssignment?
        func save(_ item: BatchedClaimAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedClaimAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedClaimAssignmentStore: BatchedClaimAssignmentStore {
        var items: [String: BatchedClaimAssignment]
        var order: [String]

        init(items: [String: BatchedClaimAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedClaimAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedClaimAssignment) {
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

        func list() -> [BatchedClaimAssignment] {
            var out: [BatchedClaimAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedClaimAssignmentStore() -> any BatchedClaimAssignmentStore {
        return MemoryBatchedClaimAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedClaimAssignmentStore: BatchedClaimAssignmentStore {
        var inner: MemoryBatchedClaimAssignmentStore
        var cache: TTLCache<BatchedClaimAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedClaimAssignmentStore, cache: TTLCache<BatchedClaimAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedClaimAssignment? {
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

        func save(_ item: BatchedClaimAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedClaimAssignment] {
            return inner.list()
        }
    }

    static func newCachedBatchedClaimAssignmentStore(_ inner: MemoryBatchedClaimAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedClaimAssignmentStore {
        return CachedBatchedClaimAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched claim assignments. Empty fields match all.
    final class BatchedClaimAssignmentQuery {
        var title: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedClaimAssignment) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedClaimAssignment]) -> [BatchedClaimAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedClaimAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedClaimAssignments(_ store: any BatchedClaimAssignmentStore, query: BatchedClaimAssignmentQuery) -> [BatchedClaimAssignment] {
        return query.apply(store.list())
    }
}
