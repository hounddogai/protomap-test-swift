import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps default acuity plan milestones by code.
    protocol DefaultAcuityPlanMilestoneStore {
        func find(_ code: String) -> DefaultAcuityPlanMilestone?
        func save(_ item: DefaultAcuityPlanMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultAcuityPlanMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultAcuityPlanMilestoneStore: DefaultAcuityPlanMilestoneStore {
        var items: [String: DefaultAcuityPlanMilestone]
        var order: [String]

        init(items: [String: DefaultAcuityPlanMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultAcuityPlanMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultAcuityPlanMilestone) {
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

        func list() -> [DefaultAcuityPlanMilestone] {
            var out: [DefaultAcuityPlanMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultAcuityPlanMilestoneStore() -> any DefaultAcuityPlanMilestoneStore {
        return MemoryDefaultAcuityPlanMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultAcuityPlanMilestoneStore: DefaultAcuityPlanMilestoneStore {
        var inner: MemoryDefaultAcuityPlanMilestoneStore
        var cache: TTLCache<DefaultAcuityPlanMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultAcuityPlanMilestoneStore, cache: TTLCache<DefaultAcuityPlanMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultAcuityPlanMilestone? {
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

        func save(_ item: DefaultAcuityPlanMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultAcuityPlanMilestone] {
            return inner.list()
        }
    }

    static func newCachedDefaultAcuityPlanMilestoneStore(_ inner: MemoryDefaultAcuityPlanMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultAcuityPlanMilestoneStore {
        return CachedDefaultAcuityPlanMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default acuity plan milestones. Empty fields match all.
    final class DefaultAcuityPlanMilestoneQuery {
        var locale: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultAcuityPlanMilestone) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [DefaultAcuityPlanMilestone]) -> [DefaultAcuityPlanMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultAcuityPlanMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultAcuityPlanMilestones(_ store: any DefaultAcuityPlanMilestoneStore, query: DefaultAcuityPlanMilestoneQuery) -> [DefaultAcuityPlanMilestone] {
        return query.apply(store.list())
    }
}
