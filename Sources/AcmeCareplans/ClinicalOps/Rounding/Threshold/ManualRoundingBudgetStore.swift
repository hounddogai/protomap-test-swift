import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps manual rounding budgets by code.
    protocol ManualRoundingBudgetStore {
        func find(_ code: String) -> ManualRoundingBudget?
        func save(_ item: ManualRoundingBudget)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRoundingBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRoundingBudgetStore: ManualRoundingBudgetStore {
        var items: [String: ManualRoundingBudget]
        var order: [String]

        init(items: [String: ManualRoundingBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRoundingBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRoundingBudget) {
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

        func list() -> [ManualRoundingBudget] {
            var out: [ManualRoundingBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRoundingBudgetStore() -> any ManualRoundingBudgetStore {
        return MemoryManualRoundingBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRoundingBudgetStore: ManualRoundingBudgetStore {
        var inner: MemoryManualRoundingBudgetStore
        var cache: TTLCache<ManualRoundingBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRoundingBudgetStore, cache: TTLCache<ManualRoundingBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRoundingBudget? {
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

        func save(_ item: ManualRoundingBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRoundingBudget] {
            return inner.list()
        }
    }

    static func newCachedManualRoundingBudgetStore(_ inner: MemoryManualRoundingBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRoundingBudgetStore {
        return CachedManualRoundingBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual rounding budgets. Empty fields match all.
    final class ManualRoundingBudgetQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRoundingBudget) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualRoundingBudget]) -> [ManualRoundingBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRoundingBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRoundingBudgets(_ store: any ManualRoundingBudgetStore, query: ManualRoundingBudgetQuery) -> [ManualRoundingBudget] {
        return query.apply(store.list())
    }
}
