import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps rolling overtime budgets by code.
    protocol RollingOvertimeBudgetStore {
        func find(_ code: String) -> RollingOvertimeBudget?
        func save(_ item: RollingOvertimeBudget)
        func remove(_ code: String) -> Bool
        func list() -> [RollingOvertimeBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingOvertimeBudgetStore: RollingOvertimeBudgetStore {
        var items: [String: RollingOvertimeBudget]
        var order: [String]

        init(items: [String: RollingOvertimeBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingOvertimeBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingOvertimeBudget) {
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

        func list() -> [RollingOvertimeBudget] {
            var out: [RollingOvertimeBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingOvertimeBudgetStore() -> any RollingOvertimeBudgetStore {
        return MemoryRollingOvertimeBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingOvertimeBudgetStore: RollingOvertimeBudgetStore {
        var inner: MemoryRollingOvertimeBudgetStore
        var cache: TTLCache<RollingOvertimeBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingOvertimeBudgetStore, cache: TTLCache<RollingOvertimeBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingOvertimeBudget? {
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

        func save(_ item: RollingOvertimeBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingOvertimeBudget] {
            return inner.list()
        }
    }

    static func newCachedRollingOvertimeBudgetStore(_ inner: MemoryRollingOvertimeBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingOvertimeBudgetStore {
        return CachedRollingOvertimeBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling overtime budgets. Empty fields match all.
    final class RollingOvertimeBudgetQuery {
        var country: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingOvertimeBudget) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingOvertimeBudget]) -> [RollingOvertimeBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingOvertimeBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingOvertimeBudgets(_ store: any RollingOvertimeBudgetStore, query: RollingOvertimeBudgetQuery) -> [RollingOvertimeBudget] {
        return query.apply(store.list())
    }
}
