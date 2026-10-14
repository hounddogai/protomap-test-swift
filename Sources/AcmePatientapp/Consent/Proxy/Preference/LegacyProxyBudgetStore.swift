import AcmePlatform
import Foundation

extension Consent {
    /// Keeps legacy proxy budgets by code.
    protocol LegacyProxyBudgetStore {
        func find(_ code: String) -> LegacyProxyBudget?
        func save(_ item: LegacyProxyBudget)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyProxyBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyProxyBudgetStore: LegacyProxyBudgetStore {
        var items: [String: LegacyProxyBudget]
        var order: [String]

        init(items: [String: LegacyProxyBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyProxyBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyProxyBudget) {
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

        func list() -> [LegacyProxyBudget] {
            var out: [LegacyProxyBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyProxyBudgetStore() -> any LegacyProxyBudgetStore {
        return MemoryLegacyProxyBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyProxyBudgetStore: LegacyProxyBudgetStore {
        var inner: MemoryLegacyProxyBudgetStore
        var cache: TTLCache<LegacyProxyBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyProxyBudgetStore, cache: TTLCache<LegacyProxyBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyProxyBudget? {
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

        func save(_ item: LegacyProxyBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyProxyBudget] {
            return inner.list()
        }
    }

    static func newCachedLegacyProxyBudgetStore(_ inner: MemoryLegacyProxyBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyProxyBudgetStore {
        return CachedLegacyProxyBudgetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy proxy budgets. Empty fields match all.
    final class LegacyProxyBudgetQuery {
        var title: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyProxyBudget) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyProxyBudget]) -> [LegacyProxyBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyProxyBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyProxyBudgets(_ store: any LegacyProxyBudgetStore, query: LegacyProxyBudgetQuery) -> [LegacyProxyBudget] {
        return query.apply(store.list())
    }
}
