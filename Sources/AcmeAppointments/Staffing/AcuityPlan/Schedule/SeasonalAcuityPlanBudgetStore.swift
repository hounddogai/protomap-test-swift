import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps seasonal acuity plan budgets by code.
    protocol SeasonalAcuityPlanBudgetStore {
        func find(_ code: String) -> SeasonalAcuityPlanBudget?
        func save(_ item: SeasonalAcuityPlanBudget)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalAcuityPlanBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalAcuityPlanBudgetStore: SeasonalAcuityPlanBudgetStore {
        var items: [String: SeasonalAcuityPlanBudget]
        var order: [String]

        init(items: [String: SeasonalAcuityPlanBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalAcuityPlanBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalAcuityPlanBudget) {
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

        func list() -> [SeasonalAcuityPlanBudget] {
            var out: [SeasonalAcuityPlanBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalAcuityPlanBudgetStore() -> any SeasonalAcuityPlanBudgetStore {
        return MemorySeasonalAcuityPlanBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalAcuityPlanBudgetStore: SeasonalAcuityPlanBudgetStore {
        var inner: MemorySeasonalAcuityPlanBudgetStore
        var cache: TTLCache<SeasonalAcuityPlanBudget>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalAcuityPlanBudgetStore, cache: TTLCache<SeasonalAcuityPlanBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalAcuityPlanBudget? {
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

        func save(_ item: SeasonalAcuityPlanBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalAcuityPlanBudget] {
            return inner.list()
        }
    }

    static func newCachedSeasonalAcuityPlanBudgetStore(_ inner: MemorySeasonalAcuityPlanBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalAcuityPlanBudgetStore {
        return CachedSeasonalAcuityPlanBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal acuity plan budgets. Empty fields match all.
    final class SeasonalAcuityPlanBudgetQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalAcuityPlanBudget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SeasonalAcuityPlanBudget]) -> [SeasonalAcuityPlanBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalAcuityPlanBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalAcuityPlanBudgets(_ store: any SeasonalAcuityPlanBudgetStore, query: SeasonalAcuityPlanBudgetQuery) -> [SeasonalAcuityPlanBudget] {
        return query.apply(store.list())
    }
}
