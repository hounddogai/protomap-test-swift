import AcmePlatform
import Foundation

extension Labs {
    /// Keeps rolling accession budgets by code.
    protocol RollingAccessionBudgetStore {
        func find(_ code: String) -> RollingAccessionBudget?
        func save(_ item: RollingAccessionBudget)
        func remove(_ code: String) -> Bool
        func list() -> [RollingAccessionBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingAccessionBudgetStore: RollingAccessionBudgetStore {
        var items: [String: RollingAccessionBudget]
        var order: [String]

        init(items: [String: RollingAccessionBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingAccessionBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingAccessionBudget) {
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

        func list() -> [RollingAccessionBudget] {
            var out: [RollingAccessionBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingAccessionBudgetStore() -> any RollingAccessionBudgetStore {
        return MemoryRollingAccessionBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingAccessionBudgetStore: RollingAccessionBudgetStore {
        var inner: MemoryRollingAccessionBudgetStore
        var cache: TTLCache<RollingAccessionBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingAccessionBudgetStore, cache: TTLCache<RollingAccessionBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingAccessionBudget? {
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

        func save(_ item: RollingAccessionBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingAccessionBudget] {
            return inner.list()
        }
    }

    static func newCachedRollingAccessionBudgetStore(_ inner: MemoryRollingAccessionBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingAccessionBudgetStore {
        return CachedRollingAccessionBudgetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling accession budgets. Empty fields match all.
    final class RollingAccessionBudgetQuery {
        var ward: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingAccessionBudget) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [RollingAccessionBudget]) -> [RollingAccessionBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingAccessionBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingAccessionBudgets(_ store: any RollingAccessionBudgetStore, query: RollingAccessionBudgetQuery) -> [RollingAccessionBudget] {
        return query.apply(store.list())
    }
}
