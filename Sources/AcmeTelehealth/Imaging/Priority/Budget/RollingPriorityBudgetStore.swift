import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps rolling priority budgets by code.
    protocol RollingPriorityBudgetStore {
        func find(_ code: String) -> RollingPriorityBudget?
        func save(_ item: RollingPriorityBudget)
        func remove(_ code: String) -> Bool
        func list() -> [RollingPriorityBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingPriorityBudgetStore: RollingPriorityBudgetStore {
        var items: [String: RollingPriorityBudget]
        var order: [String]

        init(items: [String: RollingPriorityBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingPriorityBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingPriorityBudget) {
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

        func list() -> [RollingPriorityBudget] {
            var out: [RollingPriorityBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingPriorityBudgetStore() -> any RollingPriorityBudgetStore {
        return MemoryRollingPriorityBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingPriorityBudgetStore: RollingPriorityBudgetStore {
        var inner: MemoryRollingPriorityBudgetStore
        var cache: TTLCache<RollingPriorityBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingPriorityBudgetStore, cache: TTLCache<RollingPriorityBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingPriorityBudget? {
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

        func save(_ item: RollingPriorityBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingPriorityBudget] {
            return inner.list()
        }
    }

    static func newCachedRollingPriorityBudgetStore(_ inner: MemoryRollingPriorityBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingPriorityBudgetStore {
        return CachedRollingPriorityBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling priority budgets. Empty fields match all.
    final class RollingPriorityBudgetQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingPriorityBudget) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingPriorityBudget]) -> [RollingPriorityBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingPriorityBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingPriorityBudgets(_ store: any RollingPriorityBudgetStore, query: RollingPriorityBudgetQuery) -> [RollingPriorityBudget] {
        return query.apply(store.list())
    }
}
