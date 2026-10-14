import AcmePlatform
import Foundation

extension Consent {
    /// Keeps tiered proxy budgets by code.
    protocol TieredProxyBudgetStore {
        func find(_ code: String) -> TieredProxyBudget?
        func save(_ item: TieredProxyBudget)
        func remove(_ code: String) -> Bool
        func list() -> [TieredProxyBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredProxyBudgetStore: TieredProxyBudgetStore {
        var items: [String: TieredProxyBudget]
        var order: [String]

        init(items: [String: TieredProxyBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredProxyBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredProxyBudget) {
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

        func list() -> [TieredProxyBudget] {
            var out: [TieredProxyBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredProxyBudgetStore() -> any TieredProxyBudgetStore {
        return MemoryTieredProxyBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredProxyBudgetStore: TieredProxyBudgetStore {
        var inner: MemoryTieredProxyBudgetStore
        var cache: TTLCache<TieredProxyBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredProxyBudgetStore, cache: TTLCache<TieredProxyBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredProxyBudget? {
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

        func save(_ item: TieredProxyBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredProxyBudget] {
            return inner.list()
        }
    }

    static func newCachedTieredProxyBudgetStore(_ inner: MemoryTieredProxyBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredProxyBudgetStore {
        return CachedTieredProxyBudgetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered proxy budgets. Empty fields match all.
    final class TieredProxyBudgetQuery {
        var category: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMargin: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredProxyBudget) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredProxyBudget]) -> [TieredProxyBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredProxyBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredProxyBudgets(_ store: any TieredProxyBudgetStore, query: TieredProxyBudgetQuery) -> [TieredProxyBudget] {
        return query.apply(store.list())
    }
}
