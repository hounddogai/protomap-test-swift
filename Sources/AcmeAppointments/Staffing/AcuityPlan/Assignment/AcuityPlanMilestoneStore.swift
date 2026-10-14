import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps acuity plan milestones by code.
    protocol AcuityPlanMilestoneStore {
        func find(_ code: String) -> AcuityPlanMilestone?
        func save(_ item: AcuityPlanMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [AcuityPlanMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAcuityPlanMilestoneStore: AcuityPlanMilestoneStore {
        var items: [String: AcuityPlanMilestone]
        var order: [String]

        init(items: [String: AcuityPlanMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AcuityPlanMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AcuityPlanMilestone) {
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

        func list() -> [AcuityPlanMilestone] {
            var out: [AcuityPlanMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAcuityPlanMilestoneStore() -> any AcuityPlanMilestoneStore {
        return MemoryAcuityPlanMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAcuityPlanMilestoneStore: AcuityPlanMilestoneStore {
        var inner: MemoryAcuityPlanMilestoneStore
        var cache: TTLCache<AcuityPlanMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryAcuityPlanMilestoneStore, cache: TTLCache<AcuityPlanMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AcuityPlanMilestone? {
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

        func save(_ item: AcuityPlanMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AcuityPlanMilestone] {
            return inner.list()
        }
    }

    static func newCachedAcuityPlanMilestoneStore(_ inner: MemoryAcuityPlanMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AcuityPlanMilestoneStore {
        return CachedAcuityPlanMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects acuity plan milestones. Empty fields match all.
    final class AcuityPlanMilestoneQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AcuityPlanMilestone) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AcuityPlanMilestone]) -> [AcuityPlanMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AcuityPlanMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAcuityPlanMilestones(_ store: any AcuityPlanMilestoneStore, query: AcuityPlanMilestoneQuery) -> [AcuityPlanMilestone] {
        return query.apply(store.list())
    }
}
