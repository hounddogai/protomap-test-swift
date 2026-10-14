import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive eligibility milestones by code.
    protocol AdaptiveEligibilityMilestoneStore {
        func find(_ code: String) -> AdaptiveEligibilityMilestone?
        func save(_ item: AdaptiveEligibilityMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveEligibilityMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveEligibilityMilestoneStore: AdaptiveEligibilityMilestoneStore {
        var items: [String: AdaptiveEligibilityMilestone]
        var order: [String]

        init(items: [String: AdaptiveEligibilityMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveEligibilityMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveEligibilityMilestone) {
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

        func list() -> [AdaptiveEligibilityMilestone] {
            var out: [AdaptiveEligibilityMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveEligibilityMilestoneStore() -> any AdaptiveEligibilityMilestoneStore {
        return MemoryAdaptiveEligibilityMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveEligibilityMilestoneStore: AdaptiveEligibilityMilestoneStore {
        var inner: MemoryAdaptiveEligibilityMilestoneStore
        var cache: TTLCache<AdaptiveEligibilityMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveEligibilityMilestoneStore, cache: TTLCache<AdaptiveEligibilityMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveEligibilityMilestone? {
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

        func save(_ item: AdaptiveEligibilityMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveEligibilityMilestone] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveEligibilityMilestoneStore(_ inner: MemoryAdaptiveEligibilityMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveEligibilityMilestoneStore {
        return CachedAdaptiveEligibilityMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive eligibility milestones. Empty fields match all.
    final class AdaptiveEligibilityMilestoneQuery {
        var source: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveEligibilityMilestone) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [AdaptiveEligibilityMilestone]) -> [AdaptiveEligibilityMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveEligibilityMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveEligibilityMilestones(_ store: any AdaptiveEligibilityMilestoneStore, query: AdaptiveEligibilityMilestoneQuery) -> [AdaptiveEligibilityMilestone] {
        return query.apply(store.list())
    }
}
