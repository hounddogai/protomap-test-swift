import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps pending acuity plan milestones by code.
    protocol PendingAcuityPlanMilestoneStore {
        func find(_ code: String) -> PendingAcuityPlanMilestone?
        func save(_ item: PendingAcuityPlanMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [PendingAcuityPlanMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingAcuityPlanMilestoneStore: PendingAcuityPlanMilestoneStore {
        var items: [String: PendingAcuityPlanMilestone]
        var order: [String]

        init(items: [String: PendingAcuityPlanMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingAcuityPlanMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingAcuityPlanMilestone) {
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

        func list() -> [PendingAcuityPlanMilestone] {
            var out: [PendingAcuityPlanMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingAcuityPlanMilestoneStore() -> any PendingAcuityPlanMilestoneStore {
        return MemoryPendingAcuityPlanMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingAcuityPlanMilestoneStore: PendingAcuityPlanMilestoneStore {
        var inner: MemoryPendingAcuityPlanMilestoneStore
        var cache: TTLCache<PendingAcuityPlanMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingAcuityPlanMilestoneStore, cache: TTLCache<PendingAcuityPlanMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingAcuityPlanMilestone? {
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

        func save(_ item: PendingAcuityPlanMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingAcuityPlanMilestone] {
            return inner.list()
        }
    }

    static func newCachedPendingAcuityPlanMilestoneStore(_ inner: MemoryPendingAcuityPlanMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingAcuityPlanMilestoneStore {
        return CachedPendingAcuityPlanMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending acuity plan milestones. Empty fields match all.
    final class PendingAcuityPlanMilestoneQuery {
        var label: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingAcuityPlanMilestone) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PendingAcuityPlanMilestone]) -> [PendingAcuityPlanMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingAcuityPlanMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingAcuityPlanMilestones(_ store: any PendingAcuityPlanMilestoneStore, query: PendingAcuityPlanMilestoneQuery) -> [PendingAcuityPlanMilestone] {
        return query.apply(store.list())
    }
}
