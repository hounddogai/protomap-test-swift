import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending claim budgets by code.
    protocol PendingClaimBudgetStore {
        func find(_ code: String) -> PendingClaimBudget?
        func save(_ item: PendingClaimBudget)
        func remove(_ code: String) -> Bool
        func list() -> [PendingClaimBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingClaimBudgetStore: PendingClaimBudgetStore {
        var items: [String: PendingClaimBudget]
        var order: [String]

        init(items: [String: PendingClaimBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingClaimBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingClaimBudget) {
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

        func list() -> [PendingClaimBudget] {
            var out: [PendingClaimBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingClaimBudgetStore() -> any PendingClaimBudgetStore {
        return MemoryPendingClaimBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingClaimBudgetStore: PendingClaimBudgetStore {
        var inner: MemoryPendingClaimBudgetStore
        var cache: TTLCache<PendingClaimBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingClaimBudgetStore, cache: TTLCache<PendingClaimBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingClaimBudget? {
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

        func save(_ item: PendingClaimBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingClaimBudget] {
            return inner.list()
        }
    }

    static func newCachedPendingClaimBudgetStore(_ inner: MemoryPendingClaimBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingClaimBudgetStore {
        return CachedPendingClaimBudgetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending claim budgets. Empty fields match all.
    final class PendingClaimBudgetQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingClaimBudget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingClaimBudget]) -> [PendingClaimBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingClaimBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingClaimBudgets(_ store: any PendingClaimBudgetStore, query: PendingClaimBudgetQuery) -> [PendingClaimBudget] {
        return query.apply(store.list())
    }
}
