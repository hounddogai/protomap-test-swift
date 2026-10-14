import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan milestones by code.
    protocol DischargePlanMilestoneStore {
        func find(_ code: String) -> DischargePlanMilestone?
        func save(_ item: DischargePlanMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanMilestoneStore: DischargePlanMilestoneStore {
        var items: [String: DischargePlanMilestone]
        var order: [String]

        init(items: [String: DischargePlanMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanMilestone) {
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

        func list() -> [DischargePlanMilestone] {
            var out: [DischargePlanMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanMilestoneStore() -> any DischargePlanMilestoneStore {
        return MemoryDischargePlanMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanMilestoneStore: DischargePlanMilestoneStore {
        var inner: MemoryDischargePlanMilestoneStore
        var cache: TTLCache<DischargePlanMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanMilestoneStore, cache: TTLCache<DischargePlanMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanMilestone? {
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

        func save(_ item: DischargePlanMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanMilestone] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanMilestoneStore(_ inner: MemoryDischargePlanMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanMilestoneStore {
        return CachedDischargePlanMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan milestones. Empty fields match all.
    final class DischargePlanMilestoneQuery {
        var title: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCopay: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanMilestone) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanMilestone]) -> [DischargePlanMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanMilestones(_ store: any DischargePlanMilestoneStore, query: DischargePlanMilestoneQuery) -> [DischargePlanMilestone] {
        return query.apply(store.list())
    }
}
