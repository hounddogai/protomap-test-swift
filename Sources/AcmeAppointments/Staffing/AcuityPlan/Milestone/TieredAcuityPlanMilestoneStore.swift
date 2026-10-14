import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps tiered acuity plan milestones by code.
    protocol TieredAcuityPlanMilestoneStore {
        func find(_ code: String) -> TieredAcuityPlanMilestone?
        func save(_ item: TieredAcuityPlanMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [TieredAcuityPlanMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredAcuityPlanMilestoneStore: TieredAcuityPlanMilestoneStore {
        var items: [String: TieredAcuityPlanMilestone]
        var order: [String]

        init(items: [String: TieredAcuityPlanMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredAcuityPlanMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredAcuityPlanMilestone) {
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

        func list() -> [TieredAcuityPlanMilestone] {
            var out: [TieredAcuityPlanMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredAcuityPlanMilestoneStore() -> any TieredAcuityPlanMilestoneStore {
        return MemoryTieredAcuityPlanMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredAcuityPlanMilestoneStore: TieredAcuityPlanMilestoneStore {
        var inner: MemoryTieredAcuityPlanMilestoneStore
        var cache: TTLCache<TieredAcuityPlanMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredAcuityPlanMilestoneStore, cache: TTLCache<TieredAcuityPlanMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredAcuityPlanMilestone? {
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

        func save(_ item: TieredAcuityPlanMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredAcuityPlanMilestone] {
            return inner.list()
        }
    }

    static func newCachedTieredAcuityPlanMilestoneStore(_ inner: MemoryTieredAcuityPlanMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredAcuityPlanMilestoneStore {
        return CachedTieredAcuityPlanMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered acuity plan milestones. Empty fields match all.
    final class TieredAcuityPlanMilestoneQuery {
        var ward: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMargin: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredAcuityPlanMilestone) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredAcuityPlanMilestone]) -> [TieredAcuityPlanMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredAcuityPlanMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredAcuityPlanMilestones(_ store: any TieredAcuityPlanMilestoneStore, query: TieredAcuityPlanMilestoneQuery) -> [TieredAcuityPlanMilestone] {
        return query.apply(store.list())
    }
}
