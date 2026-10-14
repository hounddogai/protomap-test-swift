import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps capped bed board budgets by code.
    protocol CappedBedBoardBudgetStore {
        func find(_ code: String) -> CappedBedBoardBudget?
        func save(_ item: CappedBedBoardBudget)
        func remove(_ code: String) -> Bool
        func list() -> [CappedBedBoardBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedBedBoardBudgetStore: CappedBedBoardBudgetStore {
        var items: [String: CappedBedBoardBudget]
        var order: [String]

        init(items: [String: CappedBedBoardBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedBedBoardBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedBedBoardBudget) {
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

        func list() -> [CappedBedBoardBudget] {
            var out: [CappedBedBoardBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedBedBoardBudgetStore() -> any CappedBedBoardBudgetStore {
        return MemoryCappedBedBoardBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedBedBoardBudgetStore: CappedBedBoardBudgetStore {
        var inner: MemoryCappedBedBoardBudgetStore
        var cache: TTLCache<CappedBedBoardBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedBedBoardBudgetStore, cache: TTLCache<CappedBedBoardBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedBedBoardBudget? {
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

        func save(_ item: CappedBedBoardBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedBedBoardBudget] {
            return inner.list()
        }
    }

    static func newCachedCappedBedBoardBudgetStore(_ inner: MemoryCappedBedBoardBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedBedBoardBudgetStore {
        return CachedCappedBedBoardBudgetStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped bed board budgets. Empty fields match all.
    final class CappedBedBoardBudgetQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedBedBoardBudget) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [CappedBedBoardBudget]) -> [CappedBedBoardBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedBedBoardBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedBedBoardBudgets(_ store: any CappedBedBoardBudgetStore, query: CappedBedBoardBudgetQuery) -> [CappedBedBoardBudget] {
        return query.apply(store.list())
    }
}
