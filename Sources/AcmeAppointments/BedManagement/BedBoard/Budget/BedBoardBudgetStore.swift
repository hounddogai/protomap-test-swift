import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board budgets by code.
    protocol BedBoardBudgetStore {
        func find(_ code: String) -> BedBoardBudget?
        func save(_ item: BedBoardBudget)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardBudgetStore: BedBoardBudgetStore {
        var items: [String: BedBoardBudget]
        var order: [String]

        init(items: [String: BedBoardBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardBudget) {
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

        func list() -> [BedBoardBudget] {
            var out: [BedBoardBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardBudgetStore() -> any BedBoardBudgetStore {
        return MemoryBedBoardBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardBudgetStore: BedBoardBudgetStore {
        var inner: MemoryBedBoardBudgetStore
        var cache: TTLCache<BedBoardBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardBudgetStore, cache: TTLCache<BedBoardBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardBudget? {
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

        func save(_ item: BedBoardBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardBudget] {
            return inner.list()
        }
    }

    static func newCachedBedBoardBudgetStore(_ inner: MemoryBedBoardBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardBudgetStore {
        return CachedBedBoardBudgetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board budgets. Empty fields match all.
    final class BedBoardBudgetQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardBudget) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardBudget]) -> [BedBoardBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardBudgets(_ store: any BedBoardBudgetStore, query: BedBoardBudgetQuery) -> [BedBoardBudget] {
        return query.apply(store.list())
    }
}
