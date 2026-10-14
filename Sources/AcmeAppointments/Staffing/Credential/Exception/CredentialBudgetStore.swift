import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps credential budgets by code.
    protocol CredentialBudgetStore {
        func find(_ code: String) -> CredentialBudget?
        func save(_ item: CredentialBudget)
        func remove(_ code: String) -> Bool
        func list() -> [CredentialBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCredentialBudgetStore: CredentialBudgetStore {
        var items: [String: CredentialBudget]
        var order: [String]

        init(items: [String: CredentialBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CredentialBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CredentialBudget) {
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

        func list() -> [CredentialBudget] {
            var out: [CredentialBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCredentialBudgetStore() -> any CredentialBudgetStore {
        return MemoryCredentialBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCredentialBudgetStore: CredentialBudgetStore {
        var inner: MemoryCredentialBudgetStore
        var cache: TTLCache<CredentialBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCredentialBudgetStore, cache: TTLCache<CredentialBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CredentialBudget? {
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

        func save(_ item: CredentialBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CredentialBudget] {
            return inner.list()
        }
    }

    static func newCachedCredentialBudgetStore(_ inner: MemoryCredentialBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CredentialBudgetStore {
        return CachedCredentialBudgetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects credential budgets. Empty fields match all.
    final class CredentialBudgetQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CredentialBudget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [CredentialBudget]) -> [CredentialBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CredentialBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCredentialBudgets(_ store: any CredentialBudgetStore, query: CredentialBudgetQuery) -> [CredentialBudget] {
        return query.apply(store.list())
    }
}
