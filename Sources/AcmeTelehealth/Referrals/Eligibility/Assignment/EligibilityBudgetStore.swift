import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility budgets by code.
    protocol EligibilityBudgetStore {
        func find(_ code: String) -> EligibilityBudget?
        func save(_ item: EligibilityBudget)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityBudgetStore: EligibilityBudgetStore {
        var items: [String: EligibilityBudget]
        var order: [String]

        init(items: [String: EligibilityBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityBudget) {
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

        func list() -> [EligibilityBudget] {
            var out: [EligibilityBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityBudgetStore() -> any EligibilityBudgetStore {
        return MemoryEligibilityBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityBudgetStore: EligibilityBudgetStore {
        var inner: MemoryEligibilityBudgetStore
        var cache: TTLCache<EligibilityBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityBudgetStore, cache: TTLCache<EligibilityBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityBudget? {
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

        func save(_ item: EligibilityBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityBudget] {
            return inner.list()
        }
    }

    static func newCachedEligibilityBudgetStore(_ inner: MemoryEligibilityBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityBudgetStore {
        return CachedEligibilityBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility budgets. Empty fields match all.
    final class EligibilityBudgetQuery {
        var name: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityBudget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityBudget]) -> [EligibilityBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityBudgets(_ store: any EligibilityBudgetStore, query: EligibilityBudgetQuery) -> [EligibilityBudget] {
        return query.apply(store.list())
    }
}
