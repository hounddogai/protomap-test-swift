import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps scheduled eligibility plans by code.
    protocol ScheduledEligibilityPlanStore {
        func find(_ code: String) -> ScheduledEligibilityPlan?
        func save(_ item: ScheduledEligibilityPlan)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledEligibilityPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledEligibilityPlanStore: ScheduledEligibilityPlanStore {
        var items: [String: ScheduledEligibilityPlan]
        var order: [String]

        init(items: [String: ScheduledEligibilityPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledEligibilityPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledEligibilityPlan) {
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

        func list() -> [ScheduledEligibilityPlan] {
            var out: [ScheduledEligibilityPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledEligibilityPlanStore() -> any ScheduledEligibilityPlanStore {
        return MemoryScheduledEligibilityPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledEligibilityPlanStore: ScheduledEligibilityPlanStore {
        var inner: MemoryScheduledEligibilityPlanStore
        var cache: TTLCache<ScheduledEligibilityPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledEligibilityPlanStore, cache: TTLCache<ScheduledEligibilityPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledEligibilityPlan? {
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

        func save(_ item: ScheduledEligibilityPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledEligibilityPlan] {
            return inner.list()
        }
    }

    static func newCachedScheduledEligibilityPlanStore(_ inner: MemoryScheduledEligibilityPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledEligibilityPlanStore {
        return CachedScheduledEligibilityPlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled eligibility plans. Empty fields match all.
    final class ScheduledEligibilityPlanQuery {
        var locale: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledEligibilityPlan) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledEligibilityPlan]) -> [ScheduledEligibilityPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledEligibilityPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledEligibilityPlans(_ store: any ScheduledEligibilityPlanStore, query: ScheduledEligibilityPlanQuery) -> [ScheduledEligibilityPlan] {
        return query.apply(store.list())
    }
}
