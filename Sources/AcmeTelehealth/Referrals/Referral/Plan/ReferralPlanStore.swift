import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral plans by code.
    protocol ReferralPlanStore {
        func find(_ code: String) -> ReferralPlan?
        func save(_ item: ReferralPlan)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralPlanStore: ReferralPlanStore {
        var items: [String: ReferralPlan]
        var order: [String]

        init(items: [String: ReferralPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralPlan) {
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

        func list() -> [ReferralPlan] {
            var out: [ReferralPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralPlanStore() -> any ReferralPlanStore {
        return MemoryReferralPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralPlanStore: ReferralPlanStore {
        var inner: MemoryReferralPlanStore
        var cache: TTLCache<ReferralPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralPlanStore, cache: TTLCache<ReferralPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralPlan? {
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

        func save(_ item: ReferralPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralPlan] {
            return inner.list()
        }
    }

    static func newCachedReferralPlanStore(_ inner: MemoryReferralPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralPlanStore {
        return CachedReferralPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral plans. Empty fields match all.
    final class ReferralPlanQuery {
        var title: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralPlan]) -> [ReferralPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralPlans(_ store: any ReferralPlanStore, query: ReferralPlanQuery) -> [ReferralPlan] {
        return query.apply(store.list())
    }
}
