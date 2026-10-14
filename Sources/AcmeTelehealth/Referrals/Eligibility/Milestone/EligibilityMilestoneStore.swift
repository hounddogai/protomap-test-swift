import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility milestones by code.
    protocol EligibilityMilestoneStore {
        func find(_ code: String) -> EligibilityMilestone?
        func save(_ item: EligibilityMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityMilestoneStore: EligibilityMilestoneStore {
        var items: [String: EligibilityMilestone]
        var order: [String]

        init(items: [String: EligibilityMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityMilestone) {
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

        func list() -> [EligibilityMilestone] {
            var out: [EligibilityMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityMilestoneStore() -> any EligibilityMilestoneStore {
        return MemoryEligibilityMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityMilestoneStore: EligibilityMilestoneStore {
        var inner: MemoryEligibilityMilestoneStore
        var cache: TTLCache<EligibilityMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityMilestoneStore, cache: TTLCache<EligibilityMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityMilestone? {
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

        func save(_ item: EligibilityMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityMilestone] {
            return inner.list()
        }
    }

    static func newCachedEligibilityMilestoneStore(_ inner: MemoryEligibilityMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityMilestoneStore {
        return CachedEligibilityMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility milestones. Empty fields match all.
    final class EligibilityMilestoneQuery {
        var name: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityMilestone) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityMilestone]) -> [EligibilityMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityMilestones(_ store: any EligibilityMilestoneStore, query: EligibilityMilestoneQuery) -> [EligibilityMilestone] {
        return query.apply(store.list())
    }
}
