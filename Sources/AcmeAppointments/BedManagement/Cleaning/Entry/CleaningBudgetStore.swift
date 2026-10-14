import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning budgets by code.
    protocol CleaningBudgetStore {
        func find(_ code: String) -> CleaningBudget?
        func save(_ item: CleaningBudget)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningBudgetStore: CleaningBudgetStore {
        var items: [String: CleaningBudget]
        var order: [String]

        init(items: [String: CleaningBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningBudget) {
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

        func list() -> [CleaningBudget] {
            var out: [CleaningBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningBudgetStore() -> any CleaningBudgetStore {
        return MemoryCleaningBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningBudgetStore: CleaningBudgetStore {
        var inner: MemoryCleaningBudgetStore
        var cache: TTLCache<CleaningBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningBudgetStore, cache: TTLCache<CleaningBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningBudget? {
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

        func save(_ item: CleaningBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningBudget] {
            return inner.list()
        }
    }

    static func newCachedCleaningBudgetStore(_ inner: MemoryCleaningBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningBudgetStore {
        return CachedCleaningBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning budgets. Empty fields match all.
    final class CleaningBudgetQuery {
        var name: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningBudget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningBudget]) -> [CleaningBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningBudgets(_ store: any CleaningBudgetStore, query: CleaningBudgetQuery) -> [CleaningBudget] {
        return query.apply(store.list())
    }
}
