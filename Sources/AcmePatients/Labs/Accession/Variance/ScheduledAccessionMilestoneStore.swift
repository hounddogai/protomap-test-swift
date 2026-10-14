import AcmePlatform
import Foundation

extension Labs {
    /// Keeps scheduled accession milestones by code.
    protocol ScheduledAccessionMilestoneStore {
        func find(_ code: String) -> ScheduledAccessionMilestone?
        func save(_ item: ScheduledAccessionMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledAccessionMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledAccessionMilestoneStore: ScheduledAccessionMilestoneStore {
        var items: [String: ScheduledAccessionMilestone]
        var order: [String]

        init(items: [String: ScheduledAccessionMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledAccessionMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledAccessionMilestone) {
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

        func list() -> [ScheduledAccessionMilestone] {
            var out: [ScheduledAccessionMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledAccessionMilestoneStore() -> any ScheduledAccessionMilestoneStore {
        return MemoryScheduledAccessionMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledAccessionMilestoneStore: ScheduledAccessionMilestoneStore {
        var inner: MemoryScheduledAccessionMilestoneStore
        var cache: TTLCache<ScheduledAccessionMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledAccessionMilestoneStore, cache: TTLCache<ScheduledAccessionMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledAccessionMilestone? {
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

        func save(_ item: ScheduledAccessionMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledAccessionMilestone] {
            return inner.list()
        }
    }

    static func newCachedScheduledAccessionMilestoneStore(_ inner: MemoryScheduledAccessionMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledAccessionMilestoneStore {
        return CachedScheduledAccessionMilestoneStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled accession milestones. Empty fields match all.
    final class ScheduledAccessionMilestoneQuery {
        var ward: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledAccessionMilestone) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [ScheduledAccessionMilestone]) -> [ScheduledAccessionMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledAccessionMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledAccessionMilestones(_ store: any ScheduledAccessionMilestoneStore, query: ScheduledAccessionMilestoneQuery) -> [ScheduledAccessionMilestone] {
        return query.apply(store.list())
    }
}
