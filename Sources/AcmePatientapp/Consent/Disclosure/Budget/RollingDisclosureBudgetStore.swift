import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling disclosure budgets by code.
    protocol RollingDisclosureBudgetStore {
        func find(_ code: String) -> RollingDisclosureBudget?
        func save(_ item: RollingDisclosureBudget)
        func remove(_ code: String) -> Bool
        func list() -> [RollingDisclosureBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingDisclosureBudgetStore: RollingDisclosureBudgetStore {
        var items: [String: RollingDisclosureBudget]
        var order: [String]

        init(items: [String: RollingDisclosureBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingDisclosureBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingDisclosureBudget) {
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

        func list() -> [RollingDisclosureBudget] {
            var out: [RollingDisclosureBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingDisclosureBudgetStore() -> any RollingDisclosureBudgetStore {
        return MemoryRollingDisclosureBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingDisclosureBudgetStore: RollingDisclosureBudgetStore {
        var inner: MemoryRollingDisclosureBudgetStore
        var cache: TTLCache<RollingDisclosureBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingDisclosureBudgetStore, cache: TTLCache<RollingDisclosureBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingDisclosureBudget? {
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

        func save(_ item: RollingDisclosureBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingDisclosureBudget] {
            return inner.list()
        }
    }

    static func newCachedRollingDisclosureBudgetStore(_ inner: MemoryRollingDisclosureBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingDisclosureBudgetStore {
        return CachedRollingDisclosureBudgetStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling disclosure budgets. Empty fields match all.
    final class RollingDisclosureBudgetQuery {
        var label: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingDisclosureBudget) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [RollingDisclosureBudget]) -> [RollingDisclosureBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingDisclosureBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingDisclosureBudgets(_ store: any RollingDisclosureBudgetStore, query: RollingDisclosureBudgetQuery) -> [RollingDisclosureBudget] {
        return query.apply(store.list())
    }
}
