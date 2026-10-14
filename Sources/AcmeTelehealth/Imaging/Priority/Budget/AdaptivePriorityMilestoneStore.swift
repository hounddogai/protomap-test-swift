import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps adaptive priority milestones by code.
    protocol AdaptivePriorityMilestoneStore {
        func find(_ code: String) -> AdaptivePriorityMilestone?
        func save(_ item: AdaptivePriorityMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptivePriorityMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptivePriorityMilestoneStore: AdaptivePriorityMilestoneStore {
        var items: [String: AdaptivePriorityMilestone]
        var order: [String]

        init(items: [String: AdaptivePriorityMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptivePriorityMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptivePriorityMilestone) {
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

        func list() -> [AdaptivePriorityMilestone] {
            var out: [AdaptivePriorityMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptivePriorityMilestoneStore() -> any AdaptivePriorityMilestoneStore {
        return MemoryAdaptivePriorityMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptivePriorityMilestoneStore: AdaptivePriorityMilestoneStore {
        var inner: MemoryAdaptivePriorityMilestoneStore
        var cache: TTLCache<AdaptivePriorityMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptivePriorityMilestoneStore, cache: TTLCache<AdaptivePriorityMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptivePriorityMilestone? {
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

        func save(_ item: AdaptivePriorityMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptivePriorityMilestone] {
            return inner.list()
        }
    }

    static func newCachedAdaptivePriorityMilestoneStore(_ inner: MemoryAdaptivePriorityMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptivePriorityMilestoneStore {
        return CachedAdaptivePriorityMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive priority milestones. Empty fields match all.
    final class AdaptivePriorityMilestoneQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptivePriorityMilestone) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptivePriorityMilestone]) -> [AdaptivePriorityMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptivePriorityMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptivePriorityMilestones(_ store: any AdaptivePriorityMilestoneStore, query: AdaptivePriorityMilestoneQuery) -> [AdaptivePriorityMilestone] {
        return query.apply(store.list())
    }
}
