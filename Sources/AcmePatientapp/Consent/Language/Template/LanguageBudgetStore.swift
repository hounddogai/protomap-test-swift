import AcmePlatform
import Foundation

extension Consent {
    /// Keeps language budgets by code.
    protocol LanguageBudgetStore {
        func find(_ code: String) -> LanguageBudget?
        func save(_ item: LanguageBudget)
        func remove(_ code: String) -> Bool
        func list() -> [LanguageBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLanguageBudgetStore: LanguageBudgetStore {
        var items: [String: LanguageBudget]
        var order: [String]

        init(items: [String: LanguageBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LanguageBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LanguageBudget) {
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

        func list() -> [LanguageBudget] {
            var out: [LanguageBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLanguageBudgetStore() -> any LanguageBudgetStore {
        return MemoryLanguageBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLanguageBudgetStore: LanguageBudgetStore {
        var inner: MemoryLanguageBudgetStore
        var cache: TTLCache<LanguageBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryLanguageBudgetStore, cache: TTLCache<LanguageBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LanguageBudget? {
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

        func save(_ item: LanguageBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LanguageBudget] {
            return inner.list()
        }
    }

    static func newCachedLanguageBudgetStore(_ inner: MemoryLanguageBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LanguageBudgetStore {
        return CachedLanguageBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects language budgets. Empty fields match all.
    final class LanguageBudgetQuery {
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

        func matches(_ item: LanguageBudget) -> Bool {
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

        func apply(_ items: [LanguageBudget]) -> [LanguageBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LanguageBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLanguageBudgets(_ store: any LanguageBudgetStore, query: LanguageBudgetQuery) -> [LanguageBudget] {
        return query.apply(store.list())
    }
}
