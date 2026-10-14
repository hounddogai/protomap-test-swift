import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance budgets by code.
    protocol RemittanceBudgetStore {
        func find(_ code: String) -> RemittanceBudget?
        func save(_ item: RemittanceBudget)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceBudgetStore: RemittanceBudgetStore {
        var items: [String: RemittanceBudget]
        var order: [String]

        init(items: [String: RemittanceBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceBudget) {
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

        func list() -> [RemittanceBudget] {
            var out: [RemittanceBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceBudgetStore() -> any RemittanceBudgetStore {
        return MemoryRemittanceBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceBudgetStore: RemittanceBudgetStore {
        var inner: MemoryRemittanceBudgetStore
        var cache: TTLCache<RemittanceBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceBudgetStore, cache: TTLCache<RemittanceBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceBudget? {
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

        func save(_ item: RemittanceBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceBudget] {
            return inner.list()
        }
    }

    static func newCachedRemittanceBudgetStore(_ inner: MemoryRemittanceBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceBudgetStore {
        return CachedRemittanceBudgetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance budgets. Empty fields match all.
    final class RemittanceBudgetQuery {
        var region: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minLimit: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceBudget) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RemittanceBudget]) -> [RemittanceBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceBudgets(_ store: any RemittanceBudgetStore, query: RemittanceBudgetQuery) -> [RemittanceBudget] {
        return query.apply(store.list())
    }
}
