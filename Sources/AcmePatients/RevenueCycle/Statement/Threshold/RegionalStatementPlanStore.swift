import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps regional statement plans by code.
    protocol RegionalStatementPlanStore {
        func find(_ code: String) -> RegionalStatementPlan?
        func save(_ item: RegionalStatementPlan)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalStatementPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalStatementPlanStore: RegionalStatementPlanStore {
        var items: [String: RegionalStatementPlan]
        var order: [String]

        init(items: [String: RegionalStatementPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalStatementPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalStatementPlan) {
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

        func list() -> [RegionalStatementPlan] {
            var out: [RegionalStatementPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalStatementPlanStore() -> any RegionalStatementPlanStore {
        return MemoryRegionalStatementPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalStatementPlanStore: RegionalStatementPlanStore {
        var inner: MemoryRegionalStatementPlanStore
        var cache: TTLCache<RegionalStatementPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalStatementPlanStore, cache: TTLCache<RegionalStatementPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalStatementPlan? {
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

        func save(_ item: RegionalStatementPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalStatementPlan] {
            return inner.list()
        }
    }

    static func newCachedRegionalStatementPlanStore(_ inner: MemoryRegionalStatementPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalStatementPlanStore {
        return CachedRegionalStatementPlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional statement plans. Empty fields match all.
    final class RegionalStatementPlanQuery {
        var title: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalStatementPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RegionalStatementPlan]) -> [RegionalStatementPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalStatementPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalStatementPlans(_ store: any RegionalStatementPlanStore, query: RegionalStatementPlanQuery) -> [RegionalStatementPlan] {
        return query.apply(store.list())
    }
}
