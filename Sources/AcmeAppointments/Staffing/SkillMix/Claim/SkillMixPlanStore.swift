import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix plans by code.
    protocol SkillMixPlanStore {
        func find(_ code: String) -> SkillMixPlan?
        func save(_ item: SkillMixPlan)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixPlanStore: SkillMixPlanStore {
        var items: [String: SkillMixPlan]
        var order: [String]

        init(items: [String: SkillMixPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixPlan) {
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

        func list() -> [SkillMixPlan] {
            var out: [SkillMixPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixPlanStore() -> any SkillMixPlanStore {
        return MemorySkillMixPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixPlanStore: SkillMixPlanStore {
        var inner: MemorySkillMixPlanStore
        var cache: TTLCache<SkillMixPlan>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixPlanStore, cache: TTLCache<SkillMixPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixPlan? {
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

        func save(_ item: SkillMixPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixPlan] {
            return inner.list()
        }
    }

    static func newCachedSkillMixPlanStore(_ inner: MemorySkillMixPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixPlanStore {
        return CachedSkillMixPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix plans. Empty fields match all.
    final class SkillMixPlanQuery {
        var country: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minAmount: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixPlan) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixPlan]) -> [SkillMixPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixPlans(_ store: any SkillMixPlanStore, query: SkillMixPlanQuery) -> [SkillMixPlan] {
        return query.apply(store.list())
    }
}
