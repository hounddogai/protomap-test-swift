import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps tiered task milestones by code.
    protocol TieredTaskMilestoneStore {
        func find(_ code: String) -> TieredTaskMilestone?
        func save(_ item: TieredTaskMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [TieredTaskMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredTaskMilestoneStore: TieredTaskMilestoneStore {
        var items: [String: TieredTaskMilestone]
        var order: [String]

        init(items: [String: TieredTaskMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredTaskMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredTaskMilestone) {
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

        func list() -> [TieredTaskMilestone] {
            var out: [TieredTaskMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredTaskMilestoneStore() -> any TieredTaskMilestoneStore {
        return MemoryTieredTaskMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredTaskMilestoneStore: TieredTaskMilestoneStore {
        var inner: MemoryTieredTaskMilestoneStore
        var cache: TTLCache<TieredTaskMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredTaskMilestoneStore, cache: TTLCache<TieredTaskMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredTaskMilestone? {
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

        func save(_ item: TieredTaskMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredTaskMilestone] {
            return inner.list()
        }
    }

    static func newCachedTieredTaskMilestoneStore(_ inner: MemoryTieredTaskMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredTaskMilestoneStore {
        return CachedTieredTaskMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered task milestones. Empty fields match all.
    final class TieredTaskMilestoneQuery {
        var category: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredTaskMilestone) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredTaskMilestone]) -> [TieredTaskMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredTaskMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredTaskMilestones(_ store: any TieredTaskMilestoneStore, query: TieredTaskMilestoneQuery) -> [TieredTaskMilestone] {
        return query.apply(store.list())
    }
}
