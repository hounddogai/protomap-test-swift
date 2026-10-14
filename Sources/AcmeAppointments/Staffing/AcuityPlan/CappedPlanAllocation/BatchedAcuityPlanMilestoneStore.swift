import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps batched acuity plan milestones by code.
    protocol BatchedAcuityPlanMilestoneStore {
        func find(_ code: String) -> BatchedAcuityPlanMilestone?
        func save(_ item: BatchedAcuityPlanMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedAcuityPlanMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedAcuityPlanMilestoneStore: BatchedAcuityPlanMilestoneStore {
        var items: [String: BatchedAcuityPlanMilestone]
        var order: [String]

        init(items: [String: BatchedAcuityPlanMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedAcuityPlanMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedAcuityPlanMilestone) {
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

        func list() -> [BatchedAcuityPlanMilestone] {
            var out: [BatchedAcuityPlanMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedAcuityPlanMilestoneStore() -> any BatchedAcuityPlanMilestoneStore {
        return MemoryBatchedAcuityPlanMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedAcuityPlanMilestoneStore: BatchedAcuityPlanMilestoneStore {
        var inner: MemoryBatchedAcuityPlanMilestoneStore
        var cache: TTLCache<BatchedAcuityPlanMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedAcuityPlanMilestoneStore, cache: TTLCache<BatchedAcuityPlanMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedAcuityPlanMilestone? {
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

        func save(_ item: BatchedAcuityPlanMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedAcuityPlanMilestone] {
            return inner.list()
        }
    }

    static func newCachedBatchedAcuityPlanMilestoneStore(_ inner: MemoryBatchedAcuityPlanMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedAcuityPlanMilestoneStore {
        return CachedBatchedAcuityPlanMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched acuity plan milestones. Empty fields match all.
    final class BatchedAcuityPlanMilestoneQuery {
        var region: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedAcuityPlanMilestone) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [BatchedAcuityPlanMilestone]) -> [BatchedAcuityPlanMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedAcuityPlanMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedAcuityPlanMilestones(_ store: any BatchedAcuityPlanMilestoneStore, query: BatchedAcuityPlanMilestoneQuery) -> [BatchedAcuityPlanMilestone] {
        return query.apply(store.list())
    }
}
