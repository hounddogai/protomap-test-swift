import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps scheduled census milestones by code.
    protocol ScheduledCensusMilestoneStore {
        func find(_ code: String) -> ScheduledCensusMilestone?
        func save(_ item: ScheduledCensusMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCensusMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCensusMilestoneStore: ScheduledCensusMilestoneStore {
        var items: [String: ScheduledCensusMilestone]
        var order: [String]

        init(items: [String: ScheduledCensusMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCensusMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCensusMilestone) {
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

        func list() -> [ScheduledCensusMilestone] {
            var out: [ScheduledCensusMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCensusMilestoneStore() -> any ScheduledCensusMilestoneStore {
        return MemoryScheduledCensusMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCensusMilestoneStore: ScheduledCensusMilestoneStore {
        var inner: MemoryScheduledCensusMilestoneStore
        var cache: TTLCache<ScheduledCensusMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCensusMilestoneStore, cache: TTLCache<ScheduledCensusMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCensusMilestone? {
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

        func save(_ item: ScheduledCensusMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCensusMilestone] {
            return inner.list()
        }
    }

    static func newCachedScheduledCensusMilestoneStore(_ inner: MemoryScheduledCensusMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCensusMilestoneStore {
        return CachedScheduledCensusMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled census milestones. Empty fields match all.
    final class ScheduledCensusMilestoneQuery {
        var category: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCensusMilestone) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledCensusMilestone]) -> [ScheduledCensusMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCensusMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCensusMilestones(_ store: any ScheduledCensusMilestoneStore, query: ScheduledCensusMilestoneQuery) -> [ScheduledCensusMilestone] {
        return query.apply(store.list())
    }
}
