import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps legacy claim budgets by code.
    protocol LegacyClaimBudgetStore {
        func find(_ code: String) -> LegacyClaimBudget?
        func save(_ item: LegacyClaimBudget)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyClaimBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyClaimBudgetStore: LegacyClaimBudgetStore {
        var items: [String: LegacyClaimBudget]
        var order: [String]

        init(items: [String: LegacyClaimBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyClaimBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyClaimBudget) {
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

        func list() -> [LegacyClaimBudget] {
            var out: [LegacyClaimBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyClaimBudgetStore() -> any LegacyClaimBudgetStore {
        return MemoryLegacyClaimBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyClaimBudgetStore: LegacyClaimBudgetStore {
        var inner: MemoryLegacyClaimBudgetStore
        var cache: TTLCache<LegacyClaimBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyClaimBudgetStore, cache: TTLCache<LegacyClaimBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyClaimBudget? {
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

        func save(_ item: LegacyClaimBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyClaimBudget] {
            return inner.list()
        }
    }

    static func newCachedLegacyClaimBudgetStore(_ inner: MemoryLegacyClaimBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyClaimBudgetStore {
        return CachedLegacyClaimBudgetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy claim budgets. Empty fields match all.
    final class LegacyClaimBudgetQuery {
        var ward: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minRate: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyClaimBudget) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyClaimBudget]) -> [LegacyClaimBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyClaimBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyClaimBudgets(_ store: any LegacyClaimBudgetStore, query: LegacyClaimBudgetQuery) -> [LegacyClaimBudget] {
        return query.apply(store.list())
    }
}
