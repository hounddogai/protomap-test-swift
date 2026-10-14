import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered remittance budgets by code.
    protocol TieredRemittanceBudgetStore {
        func find(_ code: String) -> TieredRemittanceBudget?
        func save(_ item: TieredRemittanceBudget)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRemittanceBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRemittanceBudgetStore: TieredRemittanceBudgetStore {
        var items: [String: TieredRemittanceBudget]
        var order: [String]

        init(items: [String: TieredRemittanceBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRemittanceBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRemittanceBudget) {
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

        func list() -> [TieredRemittanceBudget] {
            var out: [TieredRemittanceBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRemittanceBudgetStore() -> any TieredRemittanceBudgetStore {
        return MemoryTieredRemittanceBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRemittanceBudgetStore: TieredRemittanceBudgetStore {
        var inner: MemoryTieredRemittanceBudgetStore
        var cache: TTLCache<TieredRemittanceBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRemittanceBudgetStore, cache: TTLCache<TieredRemittanceBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRemittanceBudget? {
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

        func save(_ item: TieredRemittanceBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRemittanceBudget] {
            return inner.list()
        }
    }

    static func newCachedTieredRemittanceBudgetStore(_ inner: MemoryTieredRemittanceBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRemittanceBudgetStore {
        return CachedTieredRemittanceBudgetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered remittance budgets. Empty fields match all.
    final class TieredRemittanceBudgetQuery {
        var ward: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minRatio: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRemittanceBudget) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredRemittanceBudget]) -> [TieredRemittanceBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRemittanceBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRemittanceBudgets(_ store: any TieredRemittanceBudgetStore, query: TieredRemittanceBudgetQuery) -> [TieredRemittanceBudget] {
        return query.apply(store.list())
    }
}
