import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps scheduled claim milestones by code.
    protocol ScheduledClaimMilestoneStore {
        func find(_ code: String) -> ScheduledClaimMilestone?
        func save(_ item: ScheduledClaimMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledClaimMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledClaimMilestoneStore: ScheduledClaimMilestoneStore {
        var items: [String: ScheduledClaimMilestone]
        var order: [String]

        init(items: [String: ScheduledClaimMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledClaimMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledClaimMilestone) {
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

        func list() -> [ScheduledClaimMilestone] {
            var out: [ScheduledClaimMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledClaimMilestoneStore() -> any ScheduledClaimMilestoneStore {
        return MemoryScheduledClaimMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledClaimMilestoneStore: ScheduledClaimMilestoneStore {
        var inner: MemoryScheduledClaimMilestoneStore
        var cache: TTLCache<ScheduledClaimMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledClaimMilestoneStore, cache: TTLCache<ScheduledClaimMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledClaimMilestone? {
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

        func save(_ item: ScheduledClaimMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledClaimMilestone] {
            return inner.list()
        }
    }

    static func newCachedScheduledClaimMilestoneStore(_ inner: MemoryScheduledClaimMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledClaimMilestoneStore {
        return CachedScheduledClaimMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled claim milestones. Empty fields match all.
    final class ScheduledClaimMilestoneQuery {
        var source: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledClaimMilestone) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [ScheduledClaimMilestone]) -> [ScheduledClaimMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledClaimMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledClaimMilestones(_ store: any ScheduledClaimMilestoneStore, query: ScheduledClaimMilestoneQuery) -> [ScheduledClaimMilestone] {
        return query.apply(store.list())
    }
}
