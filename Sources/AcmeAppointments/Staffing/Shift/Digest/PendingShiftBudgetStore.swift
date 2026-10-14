import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps pending shift budgets by code.
    protocol PendingShiftBudgetStore {
        func find(_ code: String) -> PendingShiftBudget?
        func save(_ item: PendingShiftBudget)
        func remove(_ code: String) -> Bool
        func list() -> [PendingShiftBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingShiftBudgetStore: PendingShiftBudgetStore {
        var items: [String: PendingShiftBudget]
        var order: [String]

        init(items: [String: PendingShiftBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingShiftBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingShiftBudget) {
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

        func list() -> [PendingShiftBudget] {
            var out: [PendingShiftBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingShiftBudgetStore() -> any PendingShiftBudgetStore {
        return MemoryPendingShiftBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingShiftBudgetStore: PendingShiftBudgetStore {
        var inner: MemoryPendingShiftBudgetStore
        var cache: TTLCache<PendingShiftBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingShiftBudgetStore, cache: TTLCache<PendingShiftBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingShiftBudget? {
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

        func save(_ item: PendingShiftBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingShiftBudget] {
            return inner.list()
        }
    }

    static func newCachedPendingShiftBudgetStore(_ inner: MemoryPendingShiftBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingShiftBudgetStore {
        return CachedPendingShiftBudgetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending shift budgets. Empty fields match all.
    final class PendingShiftBudgetQuery {
        var locale: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingShiftBudget) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingShiftBudget]) -> [PendingShiftBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingShiftBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingShiftBudgets(_ store: any PendingShiftBudgetStore, query: PendingShiftBudgetQuery) -> [PendingShiftBudget] {
        return query.apply(store.list())
    }
}
