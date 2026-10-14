import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool budgets by code.
    protocol FloatPoolBudgetStore {
        func find(_ code: String) -> FloatPoolBudget?
        func save(_ item: FloatPoolBudget)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolBudgetStore: FloatPoolBudgetStore {
        var items: [String: FloatPoolBudget]
        var order: [String]

        init(items: [String: FloatPoolBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolBudget) {
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

        func list() -> [FloatPoolBudget] {
            var out: [FloatPoolBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolBudgetStore() -> any FloatPoolBudgetStore {
        return MemoryFloatPoolBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolBudgetStore: FloatPoolBudgetStore {
        var inner: MemoryFloatPoolBudgetStore
        var cache: TTLCache<FloatPoolBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolBudgetStore, cache: TTLCache<FloatPoolBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolBudget? {
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

        func save(_ item: FloatPoolBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolBudget] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolBudgetStore(_ inner: MemoryFloatPoolBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolBudgetStore {
        return CachedFloatPoolBudgetStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool budgets. Empty fields match all.
    final class FloatPoolBudgetQuery {
        var segment: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolBudget) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolBudget]) -> [FloatPoolBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolBudgets(_ store: any FloatPoolBudgetStore, query: FloatPoolBudgetQuery) -> [FloatPoolBudget] {
        return query.apply(store.list())
    }
}
