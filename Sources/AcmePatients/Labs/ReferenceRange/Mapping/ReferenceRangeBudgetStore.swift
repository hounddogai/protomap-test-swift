import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range budgets by code.
    protocol ReferenceRangeBudgetStore {
        func find(_ code: String) -> ReferenceRangeBudget?
        func save(_ item: ReferenceRangeBudget)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeBudgetStore: ReferenceRangeBudgetStore {
        var items: [String: ReferenceRangeBudget]
        var order: [String]

        init(items: [String: ReferenceRangeBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeBudget) {
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

        func list() -> [ReferenceRangeBudget] {
            var out: [ReferenceRangeBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeBudgetStore() -> any ReferenceRangeBudgetStore {
        return MemoryReferenceRangeBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeBudgetStore: ReferenceRangeBudgetStore {
        var inner: MemoryReferenceRangeBudgetStore
        var cache: TTLCache<ReferenceRangeBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeBudgetStore, cache: TTLCache<ReferenceRangeBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeBudget? {
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

        func save(_ item: ReferenceRangeBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeBudget] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeBudgetStore(_ inner: MemoryReferenceRangeBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeBudgetStore {
        return CachedReferenceRangeBudgetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range budgets. Empty fields match all.
    final class ReferenceRangeBudgetQuery {
        var ward: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minRatio: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeBudget) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeBudget]) -> [ReferenceRangeBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeBudgets(_ store: any ReferenceRangeBudgetStore, query: ReferenceRangeBudgetQuery) -> [ReferenceRangeBudget] {
        return query.apply(store.list())
    }
}
