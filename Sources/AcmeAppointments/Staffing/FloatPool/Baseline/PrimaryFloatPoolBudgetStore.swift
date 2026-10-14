import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary float pool budgets by code.
    protocol PrimaryFloatPoolBudgetStore {
        func find(_ code: String) -> PrimaryFloatPoolBudget?
        func save(_ item: PrimaryFloatPoolBudget)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryFloatPoolBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryFloatPoolBudgetStore: PrimaryFloatPoolBudgetStore {
        var items: [String: PrimaryFloatPoolBudget]
        var order: [String]

        init(items: [String: PrimaryFloatPoolBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryFloatPoolBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryFloatPoolBudget) {
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

        func list() -> [PrimaryFloatPoolBudget] {
            var out: [PrimaryFloatPoolBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryFloatPoolBudgetStore() -> any PrimaryFloatPoolBudgetStore {
        return MemoryPrimaryFloatPoolBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryFloatPoolBudgetStore: PrimaryFloatPoolBudgetStore {
        var inner: MemoryPrimaryFloatPoolBudgetStore
        var cache: TTLCache<PrimaryFloatPoolBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryFloatPoolBudgetStore, cache: TTLCache<PrimaryFloatPoolBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryFloatPoolBudget? {
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

        func save(_ item: PrimaryFloatPoolBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryFloatPoolBudget] {
            return inner.list()
        }
    }

    static func newCachedPrimaryFloatPoolBudgetStore(_ inner: MemoryPrimaryFloatPoolBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryFloatPoolBudgetStore {
        return CachedPrimaryFloatPoolBudgetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary float pool budgets. Empty fields match all.
    final class PrimaryFloatPoolBudgetQuery {
        var channel: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryFloatPoolBudget) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [PrimaryFloatPoolBudget]) -> [PrimaryFloatPoolBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryFloatPoolBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryFloatPoolBudgets(_ store: any PrimaryFloatPoolBudgetStore, query: PrimaryFloatPoolBudgetQuery) -> [PrimaryFloatPoolBudget] {
        return query.apply(store.list())
    }
}
