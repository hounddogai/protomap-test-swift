import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization budgets by code.
    protocol AuthorizationBudgetStore {
        func find(_ code: String) -> AuthorizationBudget?
        func save(_ item: AuthorizationBudget)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationBudgetStore: AuthorizationBudgetStore {
        var items: [String: AuthorizationBudget]
        var order: [String]

        init(items: [String: AuthorizationBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationBudget) {
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

        func list() -> [AuthorizationBudget] {
            var out: [AuthorizationBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationBudgetStore() -> any AuthorizationBudgetStore {
        return MemoryAuthorizationBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationBudgetStore: AuthorizationBudgetStore {
        var inner: MemoryAuthorizationBudgetStore
        var cache: TTLCache<AuthorizationBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationBudgetStore, cache: TTLCache<AuthorizationBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationBudget? {
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

        func save(_ item: AuthorizationBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationBudget] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationBudgetStore(_ inner: MemoryAuthorizationBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationBudgetStore {
        return CachedAuthorizationBudgetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization budgets. Empty fields match all.
    final class AuthorizationBudgetQuery {
        var ward: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationBudget) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [AuthorizationBudget]) -> [AuthorizationBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationBudgets(_ store: any AuthorizationBudgetStore, query: AuthorizationBudgetQuery) -> [AuthorizationBudget] {
        return query.apply(store.list())
    }
}
