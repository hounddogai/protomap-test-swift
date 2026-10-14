import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps batched interaction milestones by code.
    protocol BatchedInteractionMilestoneStore {
        func find(_ code: String) -> BatchedInteractionMilestone?
        func save(_ item: BatchedInteractionMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedInteractionMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedInteractionMilestoneStore: BatchedInteractionMilestoneStore {
        var items: [String: BatchedInteractionMilestone]
        var order: [String]

        init(items: [String: BatchedInteractionMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedInteractionMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedInteractionMilestone) {
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

        func list() -> [BatchedInteractionMilestone] {
            var out: [BatchedInteractionMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedInteractionMilestoneStore() -> any BatchedInteractionMilestoneStore {
        return MemoryBatchedInteractionMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedInteractionMilestoneStore: BatchedInteractionMilestoneStore {
        var inner: MemoryBatchedInteractionMilestoneStore
        var cache: TTLCache<BatchedInteractionMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedInteractionMilestoneStore, cache: TTLCache<BatchedInteractionMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedInteractionMilestone? {
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

        func save(_ item: BatchedInteractionMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedInteractionMilestone] {
            return inner.list()
        }
    }

    static func newCachedBatchedInteractionMilestoneStore(_ inner: MemoryBatchedInteractionMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedInteractionMilestoneStore {
        return CachedBatchedInteractionMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched interaction milestones. Empty fields match all.
    final class BatchedInteractionMilestoneQuery {
        var unit: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedInteractionMilestone) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedInteractionMilestone]) -> [BatchedInteractionMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedInteractionMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedInteractionMilestones(_ store: any BatchedInteractionMilestoneStore, query: BatchedInteractionMilestoneQuery) -> [BatchedInteractionMilestone] {
        return query.apply(store.list())
    }
}
