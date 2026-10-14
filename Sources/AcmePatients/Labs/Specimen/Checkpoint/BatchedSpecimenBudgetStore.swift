import AcmePlatform
import Foundation

extension Labs {
    /// Keeps batched specimen budgets by code.
    protocol BatchedSpecimenBudgetStore {
        func find(_ code: String) -> BatchedSpecimenBudget?
        func save(_ item: BatchedSpecimenBudget)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedSpecimenBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedSpecimenBudgetStore: BatchedSpecimenBudgetStore {
        var items: [String: BatchedSpecimenBudget]
        var order: [String]

        init(items: [String: BatchedSpecimenBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedSpecimenBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedSpecimenBudget) {
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

        func list() -> [BatchedSpecimenBudget] {
            var out: [BatchedSpecimenBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedSpecimenBudgetStore() -> any BatchedSpecimenBudgetStore {
        return MemoryBatchedSpecimenBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedSpecimenBudgetStore: BatchedSpecimenBudgetStore {
        var inner: MemoryBatchedSpecimenBudgetStore
        var cache: TTLCache<BatchedSpecimenBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedSpecimenBudgetStore, cache: TTLCache<BatchedSpecimenBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedSpecimenBudget? {
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

        func save(_ item: BatchedSpecimenBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedSpecimenBudget] {
            return inner.list()
        }
    }

    static func newCachedBatchedSpecimenBudgetStore(_ inner: MemoryBatchedSpecimenBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedSpecimenBudgetStore {
        return CachedBatchedSpecimenBudgetStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched specimen budgets. Empty fields match all.
    final class BatchedSpecimenBudgetQuery {
        var segment: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedSpecimenBudget) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedSpecimenBudget]) -> [BatchedSpecimenBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedSpecimenBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedSpecimenBudgets(_ store: any BatchedSpecimenBudgetStore, query: BatchedSpecimenBudgetQuery) -> [BatchedSpecimenBudget] {
        return query.apply(store.list())
    }
}
