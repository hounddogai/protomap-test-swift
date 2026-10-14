import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback language budgets by code.
    protocol FallbackLanguageBudgetStore {
        func find(_ code: String) -> FallbackLanguageBudget?
        func save(_ item: FallbackLanguageBudget)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackLanguageBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackLanguageBudgetStore: FallbackLanguageBudgetStore {
        var items: [String: FallbackLanguageBudget]
        var order: [String]

        init(items: [String: FallbackLanguageBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackLanguageBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackLanguageBudget) {
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

        func list() -> [FallbackLanguageBudget] {
            var out: [FallbackLanguageBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackLanguageBudgetStore() -> any FallbackLanguageBudgetStore {
        return MemoryFallbackLanguageBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackLanguageBudgetStore: FallbackLanguageBudgetStore {
        var inner: MemoryFallbackLanguageBudgetStore
        var cache: TTLCache<FallbackLanguageBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackLanguageBudgetStore, cache: TTLCache<FallbackLanguageBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackLanguageBudget? {
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

        func save(_ item: FallbackLanguageBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackLanguageBudget] {
            return inner.list()
        }
    }

    static func newCachedFallbackLanguageBudgetStore(_ inner: MemoryFallbackLanguageBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackLanguageBudgetStore {
        return CachedFallbackLanguageBudgetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback language budgets. Empty fields match all.
    final class FallbackLanguageBudgetQuery {
        var ward: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackLanguageBudget) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackLanguageBudget]) -> [FallbackLanguageBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackLanguageBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackLanguageBudgets(_ store: any FallbackLanguageBudgetStore, query: FallbackLanguageBudgetQuery) -> [FallbackLanguageBudget] {
        return query.apply(store.list())
    }
}
