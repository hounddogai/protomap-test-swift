import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered closure milestones by code.
    protocol TieredClosureMilestoneStore {
        func find(_ code: String) -> TieredClosureMilestone?
        func save(_ item: TieredClosureMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [TieredClosureMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredClosureMilestoneStore: TieredClosureMilestoneStore {
        var items: [String: TieredClosureMilestone]
        var order: [String]

        init(items: [String: TieredClosureMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredClosureMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredClosureMilestone) {
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

        func list() -> [TieredClosureMilestone] {
            var out: [TieredClosureMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredClosureMilestoneStore() -> any TieredClosureMilestoneStore {
        return MemoryTieredClosureMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredClosureMilestoneStore: TieredClosureMilestoneStore {
        var inner: MemoryTieredClosureMilestoneStore
        var cache: TTLCache<TieredClosureMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredClosureMilestoneStore, cache: TTLCache<TieredClosureMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredClosureMilestone? {
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

        func save(_ item: TieredClosureMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredClosureMilestone] {
            return inner.list()
        }
    }

    static func newCachedTieredClosureMilestoneStore(_ inner: MemoryTieredClosureMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredClosureMilestoneStore {
        return CachedTieredClosureMilestoneStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered closure milestones. Empty fields match all.
    final class TieredClosureMilestoneQuery {
        var unit: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredClosureMilestone) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredClosureMilestone]) -> [TieredClosureMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredClosureMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredClosureMilestones(_ store: any TieredClosureMilestoneStore, query: TieredClosureMilestoneQuery) -> [TieredClosureMilestone] {
        return query.apply(store.list())
    }
}
