import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps seasonal skill mix plans by code.
    protocol SeasonalSkillMixPlanStore {
        func find(_ code: String) -> SeasonalSkillMixPlan?
        func save(_ item: SeasonalSkillMixPlan)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalSkillMixPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalSkillMixPlanStore: SeasonalSkillMixPlanStore {
        var items: [String: SeasonalSkillMixPlan]
        var order: [String]

        init(items: [String: SeasonalSkillMixPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalSkillMixPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalSkillMixPlan) {
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

        func list() -> [SeasonalSkillMixPlan] {
            var out: [SeasonalSkillMixPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalSkillMixPlanStore() -> any SeasonalSkillMixPlanStore {
        return MemorySeasonalSkillMixPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalSkillMixPlanStore: SeasonalSkillMixPlanStore {
        var inner: MemorySeasonalSkillMixPlanStore
        var cache: TTLCache<SeasonalSkillMixPlan>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalSkillMixPlanStore, cache: TTLCache<SeasonalSkillMixPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalSkillMixPlan? {
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

        func save(_ item: SeasonalSkillMixPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalSkillMixPlan] {
            return inner.list()
        }
    }

    static func newCachedSeasonalSkillMixPlanStore(_ inner: MemorySeasonalSkillMixPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalSkillMixPlanStore {
        return CachedSeasonalSkillMixPlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal skill mix plans. Empty fields match all.
    final class SeasonalSkillMixPlanQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalSkillMixPlan) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalSkillMixPlan]) -> [SeasonalSkillMixPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalSkillMixPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalSkillMixPlans(_ store: any SeasonalSkillMixPlanStore, query: SeasonalSkillMixPlanQuery) -> [SeasonalSkillMixPlan] {
        return query.apply(store.list())
    }
}
