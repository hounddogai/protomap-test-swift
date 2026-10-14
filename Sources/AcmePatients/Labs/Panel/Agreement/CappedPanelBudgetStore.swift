import AcmePlatform
import Foundation

extension Labs {
    /// Keeps capped panel budgets by code.
    protocol CappedPanelBudgetStore {
        func find(_ code: String) -> CappedPanelBudget?
        func save(_ item: CappedPanelBudget)
        func remove(_ code: String) -> Bool
        func list() -> [CappedPanelBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedPanelBudgetStore: CappedPanelBudgetStore {
        var items: [String: CappedPanelBudget]
        var order: [String]

        init(items: [String: CappedPanelBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedPanelBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedPanelBudget) {
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

        func list() -> [CappedPanelBudget] {
            var out: [CappedPanelBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedPanelBudgetStore() -> any CappedPanelBudgetStore {
        return MemoryCappedPanelBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedPanelBudgetStore: CappedPanelBudgetStore {
        var inner: MemoryCappedPanelBudgetStore
        var cache: TTLCache<CappedPanelBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedPanelBudgetStore, cache: TTLCache<CappedPanelBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedPanelBudget? {
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

        func save(_ item: CappedPanelBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedPanelBudget] {
            return inner.list()
        }
    }

    static func newCachedCappedPanelBudgetStore(_ inner: MemoryCappedPanelBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedPanelBudgetStore {
        return CachedCappedPanelBudgetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped panel budgets. Empty fields match all.
    final class CappedPanelBudgetQuery {
        var facility: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minLimit: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedPanelBudget) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
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

        func apply(_ items: [CappedPanelBudget]) -> [CappedPanelBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedPanelBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedPanelBudgets(_ store: any CappedPanelBudgetStore, query: CappedPanelBudgetQuery) -> [CappedPanelBudget] {
        return query.apply(store.list())
    }
}
