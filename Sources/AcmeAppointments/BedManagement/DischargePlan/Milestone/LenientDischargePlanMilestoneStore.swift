import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient discharge plan milestones by code.
    protocol LenientDischargePlanMilestoneStore {
        func find(_ code: String) -> LenientDischargePlanMilestone?
        func save(_ item: LenientDischargePlanMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [LenientDischargePlanMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientDischargePlanMilestoneStore: LenientDischargePlanMilestoneStore {
        var items: [String: LenientDischargePlanMilestone]
        var order: [String]

        init(items: [String: LenientDischargePlanMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientDischargePlanMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientDischargePlanMilestone) {
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

        func list() -> [LenientDischargePlanMilestone] {
            var out: [LenientDischargePlanMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientDischargePlanMilestoneStore() -> any LenientDischargePlanMilestoneStore {
        return MemoryLenientDischargePlanMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientDischargePlanMilestoneStore: LenientDischargePlanMilestoneStore {
        var inner: MemoryLenientDischargePlanMilestoneStore
        var cache: TTLCache<LenientDischargePlanMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientDischargePlanMilestoneStore, cache: TTLCache<LenientDischargePlanMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientDischargePlanMilestone? {
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

        func save(_ item: LenientDischargePlanMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientDischargePlanMilestone] {
            return inner.list()
        }
    }

    static func newCachedLenientDischargePlanMilestoneStore(_ inner: MemoryLenientDischargePlanMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientDischargePlanMilestoneStore {
        return CachedLenientDischargePlanMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient discharge plan milestones. Empty fields match all.
    final class LenientDischargePlanMilestoneQuery {
        var segment: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientDischargePlanMilestone) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientDischargePlanMilestone]) -> [LenientDischargePlanMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientDischargePlanMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientDischargePlanMilestones(_ store: any LenientDischargePlanMilestoneStore, query: LenientDischargePlanMilestoneQuery) -> [LenientDischargePlanMilestone] {
        return query.apply(store.list())
    }
}
