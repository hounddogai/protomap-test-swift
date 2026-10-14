import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps discharge plan budgets by code.
    protocol DischargePlanBudgetStore {
        func find(_ code: String) -> DischargePlanBudget?
        func save(_ item: DischargePlanBudget)
        func remove(_ code: String) -> Bool
        func list() -> [DischargePlanBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDischargePlanBudgetStore: DischargePlanBudgetStore {
        var items: [String: DischargePlanBudget]
        var order: [String]

        init(items: [String: DischargePlanBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DischargePlanBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DischargePlanBudget) {
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

        func list() -> [DischargePlanBudget] {
            var out: [DischargePlanBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDischargePlanBudgetStore() -> any DischargePlanBudgetStore {
        return MemoryDischargePlanBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDischargePlanBudgetStore: DischargePlanBudgetStore {
        var inner: MemoryDischargePlanBudgetStore
        var cache: TTLCache<DischargePlanBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryDischargePlanBudgetStore, cache: TTLCache<DischargePlanBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DischargePlanBudget? {
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

        func save(_ item: DischargePlanBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DischargePlanBudget] {
            return inner.list()
        }
    }

    static func newCachedDischargePlanBudgetStore(_ inner: MemoryDischargePlanBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DischargePlanBudgetStore {
        return CachedDischargePlanBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects discharge plan budgets. Empty fields match all.
    final class DischargePlanBudgetQuery {
        var region: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minLimit: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DischargePlanBudget) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DischargePlanBudget]) -> [DischargePlanBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DischargePlanBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDischargePlanBudgets(_ store: any DischargePlanBudgetStore, query: DischargePlanBudgetQuery) -> [DischargePlanBudget] {
        return query.apply(store.list())
    }
}
