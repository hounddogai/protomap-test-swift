import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched care gap assignments by code.
    protocol BatchedCareGapAssignmentStore {
        func find(_ code: String) -> BatchedCareGapAssignment?
        func save(_ item: BatchedCareGapAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCareGapAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCareGapAssignmentStore: BatchedCareGapAssignmentStore {
        var items: [String: BatchedCareGapAssignment]
        var order: [String]

        init(items: [String: BatchedCareGapAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCareGapAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCareGapAssignment) {
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

        func list() -> [BatchedCareGapAssignment] {
            var out: [BatchedCareGapAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCareGapAssignmentStore() -> any BatchedCareGapAssignmentStore {
        return MemoryBatchedCareGapAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCareGapAssignmentStore: BatchedCareGapAssignmentStore {
        var inner: MemoryBatchedCareGapAssignmentStore
        var cache: TTLCache<BatchedCareGapAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCareGapAssignmentStore, cache: TTLCache<BatchedCareGapAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCareGapAssignment? {
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

        func save(_ item: BatchedCareGapAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCareGapAssignment] {
            return inner.list()
        }
    }

    static func newCachedBatchedCareGapAssignmentStore(_ inner: MemoryBatchedCareGapAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCareGapAssignmentStore {
        return CachedBatchedCareGapAssignmentStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched care gap assignments. Empty fields match all.
    final class BatchedCareGapAssignmentQuery {
        var source: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCareGapAssignment) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [BatchedCareGapAssignment]) -> [BatchedCareGapAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCareGapAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCareGapAssignments(_ store: any BatchedCareGapAssignmentStore, query: BatchedCareGapAssignmentQuery) -> [BatchedCareGapAssignment] {
        return query.apply(store.list())
    }
}
