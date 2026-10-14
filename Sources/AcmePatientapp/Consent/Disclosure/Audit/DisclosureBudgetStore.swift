import AcmePlatform
import Foundation

extension Consent {
    /// Keeps disclosure budgets by code.
    protocol DisclosureBudgetStore {
        func find(_ code: String) -> DisclosureBudget?
        func save(_ item: DisclosureBudget)
        func remove(_ code: String) -> Bool
        func list() -> [DisclosureBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDisclosureBudgetStore: DisclosureBudgetStore {
        var items: [String: DisclosureBudget]
        var order: [String]

        init(items: [String: DisclosureBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DisclosureBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DisclosureBudget) {
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

        func list() -> [DisclosureBudget] {
            var out: [DisclosureBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDisclosureBudgetStore() -> any DisclosureBudgetStore {
        return MemoryDisclosureBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDisclosureBudgetStore: DisclosureBudgetStore {
        var inner: MemoryDisclosureBudgetStore
        var cache: TTLCache<DisclosureBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryDisclosureBudgetStore, cache: TTLCache<DisclosureBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DisclosureBudget? {
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

        func save(_ item: DisclosureBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DisclosureBudget] {
            return inner.list()
        }
    }

    static func newCachedDisclosureBudgetStore(_ inner: MemoryDisclosureBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DisclosureBudgetStore {
        return CachedDisclosureBudgetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects disclosure budgets. Empty fields match all.
    final class DisclosureBudgetQuery {
        var country: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DisclosureBudget) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [DisclosureBudget]) -> [DisclosureBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DisclosureBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDisclosureBudgets(_ store: any DisclosureBudgetStore, query: DisclosureBudgetQuery) -> [DisclosureBudget] {
        return query.apply(store.list())
    }
}
