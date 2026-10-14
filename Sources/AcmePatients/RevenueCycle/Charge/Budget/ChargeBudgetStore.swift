import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge budgets by code.
    protocol ChargeBudgetStore {
        func find(_ code: String) -> ChargeBudget?
        func save(_ item: ChargeBudget)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeBudgetStore: ChargeBudgetStore {
        var items: [String: ChargeBudget]
        var order: [String]

        init(items: [String: ChargeBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeBudget) {
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

        func list() -> [ChargeBudget] {
            var out: [ChargeBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeBudgetStore() -> any ChargeBudgetStore {
        return MemoryChargeBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeBudgetStore: ChargeBudgetStore {
        var inner: MemoryChargeBudgetStore
        var cache: TTLCache<ChargeBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeBudgetStore, cache: TTLCache<ChargeBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeBudget? {
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

        func save(_ item: ChargeBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeBudget] {
            return inner.list()
        }
    }

    static func newCachedChargeBudgetStore(_ inner: MemoryChargeBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeBudgetStore {
        return CachedChargeBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge budgets. Empty fields match all.
    final class ChargeBudgetQuery {
        var locale: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeBudget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeBudget]) -> [ChargeBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeBudgets(_ store: any ChargeBudgetStore, query: ChargeBudgetQuery) -> [ChargeBudget] {
        return query.apply(store.list())
    }
}
