import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps rolling care gap milestones by code.
    protocol RollingCareGapMilestoneStore {
        func find(_ code: String) -> RollingCareGapMilestone?
        func save(_ item: RollingCareGapMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [RollingCareGapMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingCareGapMilestoneStore: RollingCareGapMilestoneStore {
        var items: [String: RollingCareGapMilestone]
        var order: [String]

        init(items: [String: RollingCareGapMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingCareGapMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingCareGapMilestone) {
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

        func list() -> [RollingCareGapMilestone] {
            var out: [RollingCareGapMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingCareGapMilestoneStore() -> any RollingCareGapMilestoneStore {
        return MemoryRollingCareGapMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingCareGapMilestoneStore: RollingCareGapMilestoneStore {
        var inner: MemoryRollingCareGapMilestoneStore
        var cache: TTLCache<RollingCareGapMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingCareGapMilestoneStore, cache: TTLCache<RollingCareGapMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingCareGapMilestone? {
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

        func save(_ item: RollingCareGapMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingCareGapMilestone] {
            return inner.list()
        }
    }

    static func newCachedRollingCareGapMilestoneStore(_ inner: MemoryRollingCareGapMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingCareGapMilestoneStore {
        return CachedRollingCareGapMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling care gap milestones. Empty fields match all.
    final class RollingCareGapMilestoneQuery {
        var ward: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minWeight: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingCareGapMilestone) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingCareGapMilestone]) -> [RollingCareGapMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingCareGapMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingCareGapMilestones(_ store: any RollingCareGapMilestoneStore, query: RollingCareGapMilestoneQuery) -> [RollingCareGapMilestone] {
        return query.apply(store.list())
    }
}
