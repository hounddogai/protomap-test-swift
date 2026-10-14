import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched claim milestones by code.
    protocol BatchedClaimMilestoneStore {
        func find(_ code: String) -> BatchedClaimMilestone?
        func save(_ item: BatchedClaimMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedClaimMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedClaimMilestoneStore: BatchedClaimMilestoneStore {
        var items: [String: BatchedClaimMilestone]
        var order: [String]

        init(items: [String: BatchedClaimMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedClaimMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedClaimMilestone) {
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

        func list() -> [BatchedClaimMilestone] {
            var out: [BatchedClaimMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedClaimMilestoneStore() -> any BatchedClaimMilestoneStore {
        return MemoryBatchedClaimMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedClaimMilestoneStore: BatchedClaimMilestoneStore {
        var inner: MemoryBatchedClaimMilestoneStore
        var cache: TTLCache<BatchedClaimMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedClaimMilestoneStore, cache: TTLCache<BatchedClaimMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedClaimMilestone? {
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

        func save(_ item: BatchedClaimMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedClaimMilestone] {
            return inner.list()
        }
    }

    static func newCachedBatchedClaimMilestoneStore(_ inner: MemoryBatchedClaimMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedClaimMilestoneStore {
        return CachedBatchedClaimMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched claim milestones. Empty fields match all.
    final class BatchedClaimMilestoneQuery {
        var unit: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedClaimMilestone) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [BatchedClaimMilestone]) -> [BatchedClaimMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedClaimMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedClaimMilestones(_ store: any BatchedClaimMilestoneStore, query: BatchedClaimMilestoneQuery) -> [BatchedClaimMilestone] {
        return query.apply(store.list())
    }
}
