import AcmePlatform
import Foundation

extension Consent {
    /// Keeps strict proxy budgets by code.
    protocol StrictProxyBudgetStore {
        func find(_ code: String) -> StrictProxyBudget?
        func save(_ item: StrictProxyBudget)
        func remove(_ code: String) -> Bool
        func list() -> [StrictProxyBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictProxyBudgetStore: StrictProxyBudgetStore {
        var items: [String: StrictProxyBudget]
        var order: [String]

        init(items: [String: StrictProxyBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictProxyBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictProxyBudget) {
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

        func list() -> [StrictProxyBudget] {
            var out: [StrictProxyBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictProxyBudgetStore() -> any StrictProxyBudgetStore {
        return MemoryStrictProxyBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictProxyBudgetStore: StrictProxyBudgetStore {
        var inner: MemoryStrictProxyBudgetStore
        var cache: TTLCache<StrictProxyBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictProxyBudgetStore, cache: TTLCache<StrictProxyBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictProxyBudget? {
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

        func save(_ item: StrictProxyBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictProxyBudget] {
            return inner.list()
        }
    }

    static func newCachedStrictProxyBudgetStore(_ inner: MemoryStrictProxyBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictProxyBudgetStore {
        return CachedStrictProxyBudgetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict proxy budgets. Empty fields match all.
    final class StrictProxyBudgetQuery {
        var title: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictProxyBudget) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictProxyBudget]) -> [StrictProxyBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictProxyBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictProxyBudgets(_ store: any StrictProxyBudgetStore, query: StrictProxyBudgetQuery) -> [StrictProxyBudget] {
        return query.apply(store.list())
    }
}
