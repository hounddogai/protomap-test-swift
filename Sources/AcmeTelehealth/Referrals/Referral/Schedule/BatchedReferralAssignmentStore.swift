import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps batched referral assignments by code.
    protocol BatchedReferralAssignmentStore {
        func find(_ code: String) -> BatchedReferralAssignment?
        func save(_ item: BatchedReferralAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedReferralAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedReferralAssignmentStore: BatchedReferralAssignmentStore {
        var items: [String: BatchedReferralAssignment]
        var order: [String]

        init(items: [String: BatchedReferralAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedReferralAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedReferralAssignment) {
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

        func list() -> [BatchedReferralAssignment] {
            var out: [BatchedReferralAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedReferralAssignmentStore() -> any BatchedReferralAssignmentStore {
        return MemoryBatchedReferralAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedReferralAssignmentStore: BatchedReferralAssignmentStore {
        var inner: MemoryBatchedReferralAssignmentStore
        var cache: TTLCache<BatchedReferralAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedReferralAssignmentStore, cache: TTLCache<BatchedReferralAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedReferralAssignment? {
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

        func save(_ item: BatchedReferralAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedReferralAssignment] {
            return inner.list()
        }
    }

    static func newCachedBatchedReferralAssignmentStore(_ inner: MemoryBatchedReferralAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedReferralAssignmentStore {
        return CachedBatchedReferralAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched referral assignments. Empty fields match all.
    final class BatchedReferralAssignmentQuery {
        var source: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minVersion: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedReferralAssignment) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedReferralAssignment]) -> [BatchedReferralAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedReferralAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedReferralAssignments(_ store: any BatchedReferralAssignmentStore, query: BatchedReferralAssignmentQuery) -> [BatchedReferralAssignment] {
        return query.apply(store.list())
    }
}
