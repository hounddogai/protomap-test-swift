import AcmePlatform
import Foundation

extension Labs {
    /// Keeps batched panel milestones by code.
    protocol BatchedPanelMilestoneStore {
        func find(_ code: String) -> BatchedPanelMilestone?
        func save(_ item: BatchedPanelMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedPanelMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedPanelMilestoneStore: BatchedPanelMilestoneStore {
        var items: [String: BatchedPanelMilestone]
        var order: [String]

        init(items: [String: BatchedPanelMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedPanelMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedPanelMilestone) {
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

        func list() -> [BatchedPanelMilestone] {
            var out: [BatchedPanelMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedPanelMilestoneStore() -> any BatchedPanelMilestoneStore {
        return MemoryBatchedPanelMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedPanelMilestoneStore: BatchedPanelMilestoneStore {
        var inner: MemoryBatchedPanelMilestoneStore
        var cache: TTLCache<BatchedPanelMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedPanelMilestoneStore, cache: TTLCache<BatchedPanelMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedPanelMilestone? {
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

        func save(_ item: BatchedPanelMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedPanelMilestone] {
            return inner.list()
        }
    }

    static func newCachedBatchedPanelMilestoneStore(_ inner: MemoryBatchedPanelMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedPanelMilestoneStore {
        return CachedBatchedPanelMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched panel milestones. Empty fields match all.
    final class BatchedPanelMilestoneQuery {
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

        func matches(_ item: BatchedPanelMilestone) -> Bool {
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

        func apply(_ items: [BatchedPanelMilestone]) -> [BatchedPanelMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedPanelMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedPanelMilestones(_ store: any BatchedPanelMilestoneStore, query: BatchedPanelMilestoneQuery) -> [BatchedPanelMilestone] {
        return query.apply(store.list())
    }
}
