import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient substitution budgets by code.
    protocol LenientSubstitutionBudgetStore {
        func find(_ code: String) -> LenientSubstitutionBudget?
        func save(_ item: LenientSubstitutionBudget)
        func remove(_ code: String) -> Bool
        func list() -> [LenientSubstitutionBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientSubstitutionBudgetStore: LenientSubstitutionBudgetStore {
        var items: [String: LenientSubstitutionBudget]
        var order: [String]

        init(items: [String: LenientSubstitutionBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientSubstitutionBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientSubstitutionBudget) {
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

        func list() -> [LenientSubstitutionBudget] {
            var out: [LenientSubstitutionBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientSubstitutionBudgetStore() -> any LenientSubstitutionBudgetStore {
        return MemoryLenientSubstitutionBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientSubstitutionBudgetStore: LenientSubstitutionBudgetStore {
        var inner: MemoryLenientSubstitutionBudgetStore
        var cache: TTLCache<LenientSubstitutionBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientSubstitutionBudgetStore, cache: TTLCache<LenientSubstitutionBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientSubstitutionBudget? {
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

        func save(_ item: LenientSubstitutionBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientSubstitutionBudget] {
            return inner.list()
        }
    }

    static func newCachedLenientSubstitutionBudgetStore(_ inner: MemoryLenientSubstitutionBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientSubstitutionBudgetStore {
        return CachedLenientSubstitutionBudgetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient substitution budgets. Empty fields match all.
    final class LenientSubstitutionBudgetQuery {
        var category: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientSubstitutionBudget) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientSubstitutionBudget]) -> [LenientSubstitutionBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientSubstitutionBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientSubstitutionBudgets(_ store: any LenientSubstitutionBudgetStore, query: LenientSubstitutionBudgetQuery) -> [LenientSubstitutionBudget] {
        return query.apply(store.list())
    }
}
