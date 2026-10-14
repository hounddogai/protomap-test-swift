import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps task budgets by code.
    protocol TaskBudgetStore {
        func find(_ code: String) -> TaskBudget?
        func save(_ item: TaskBudget)
        func remove(_ code: String) -> Bool
        func list() -> [TaskBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTaskBudgetStore: TaskBudgetStore {
        var items: [String: TaskBudget]
        var order: [String]

        init(items: [String: TaskBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TaskBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TaskBudget) {
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

        func list() -> [TaskBudget] {
            var out: [TaskBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTaskBudgetStore() -> any TaskBudgetStore {
        return MemoryTaskBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTaskBudgetStore: TaskBudgetStore {
        var inner: MemoryTaskBudgetStore
        var cache: TTLCache<TaskBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryTaskBudgetStore, cache: TTLCache<TaskBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TaskBudget? {
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

        func save(_ item: TaskBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TaskBudget] {
            return inner.list()
        }
    }

    static func newCachedTaskBudgetStore(_ inner: MemoryTaskBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TaskBudgetStore {
        return CachedTaskBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects task budgets. Empty fields match all.
    final class TaskBudgetQuery {
        var label: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minSequence: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TaskBudget) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TaskBudget]) -> [TaskBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TaskBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTaskBudgets(_ store: any TaskBudgetStore, query: TaskBudgetQuery) -> [TaskBudget] {
        return query.apply(store.list())
    }
}
