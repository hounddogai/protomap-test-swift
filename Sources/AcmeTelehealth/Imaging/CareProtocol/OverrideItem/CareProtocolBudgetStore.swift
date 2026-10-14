import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol budgets by code.
    protocol CareProtocolBudgetStore {
        func find(_ code: String) -> CareProtocolBudget?
        func save(_ item: CareProtocolBudget)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolBudgetStore: CareProtocolBudgetStore {
        var items: [String: CareProtocolBudget]
        var order: [String]

        init(items: [String: CareProtocolBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolBudget) {
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

        func list() -> [CareProtocolBudget] {
            var out: [CareProtocolBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolBudgetStore() -> any CareProtocolBudgetStore {
        return MemoryCareProtocolBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolBudgetStore: CareProtocolBudgetStore {
        var inner: MemoryCareProtocolBudgetStore
        var cache: TTLCache<CareProtocolBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolBudgetStore, cache: TTLCache<CareProtocolBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolBudget? {
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

        func save(_ item: CareProtocolBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolBudget] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolBudgetStore(_ inner: MemoryCareProtocolBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolBudgetStore {
        return CachedCareProtocolBudgetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol budgets. Empty fields match all.
    final class CareProtocolBudgetQuery {
        var name: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minLimit: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolBudget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [CareProtocolBudget]) -> [CareProtocolBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolBudgets(_ store: any CareProtocolBudgetStore, query: CareProtocolBudgetQuery) -> [CareProtocolBudget] {
        return query.apply(store.list())
    }
}
