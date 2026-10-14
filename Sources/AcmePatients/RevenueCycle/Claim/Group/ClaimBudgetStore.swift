import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim budgets by code.
    protocol ClaimBudgetStore {
        func find(_ code: String) -> ClaimBudget?
        func save(_ item: ClaimBudget)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimBudgetStore: ClaimBudgetStore {
        var items: [String: ClaimBudget]
        var order: [String]

        init(items: [String: ClaimBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimBudget) {
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

        func list() -> [ClaimBudget] {
            var out: [ClaimBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimBudgetStore() -> any ClaimBudgetStore {
        return MemoryClaimBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimBudgetStore: ClaimBudgetStore {
        var inner: MemoryClaimBudgetStore
        var cache: TTLCache<ClaimBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimBudgetStore, cache: TTLCache<ClaimBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimBudget? {
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

        func save(_ item: ClaimBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimBudget] {
            return inner.list()
        }
    }

    static func newCachedClaimBudgetStore(_ inner: MemoryClaimBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimBudgetStore {
        return CachedClaimBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim budgets. Empty fields match all.
    final class ClaimBudgetQuery {
        var title: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimBudget) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimBudget]) -> [ClaimBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimBudgets(_ store: any ClaimBudgetStore, query: ClaimBudgetQuery) -> [ClaimBudget] {
        return query.apply(store.list())
    }
}
