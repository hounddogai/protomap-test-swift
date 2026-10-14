import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched census budgets by code.
    protocol BatchedCensusBudgetStore {
        func find(_ code: String) -> BatchedCensusBudget?
        func save(_ item: BatchedCensusBudget)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCensusBudget]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCensusBudgetStore: BatchedCensusBudgetStore {
        var items: [String: BatchedCensusBudget]
        var order: [String]

        init(items: [String: BatchedCensusBudget], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCensusBudget? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCensusBudget) {
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

        func list() -> [BatchedCensusBudget] {
            var out: [BatchedCensusBudget] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCensusBudgetStore() -> any BatchedCensusBudgetStore {
        return MemoryBatchedCensusBudgetStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCensusBudgetStore: BatchedCensusBudgetStore {
        var inner: MemoryBatchedCensusBudgetStore
        var cache: TTLCache<BatchedCensusBudget>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCensusBudgetStore, cache: TTLCache<BatchedCensusBudget>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCensusBudget? {
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

        func save(_ item: BatchedCensusBudget) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCensusBudget] {
            return inner.list()
        }
    }

    static func newCachedBatchedCensusBudgetStore(_ inner: MemoryBatchedCensusBudgetStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCensusBudgetStore {
        return CachedBatchedCensusBudgetStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched census budgets. Empty fields match all.
    final class BatchedCensusBudgetQuery {
        var source: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRefills: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCensusBudget) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedCensusBudget]) -> [BatchedCensusBudget] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCensusBudget) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCensusBudgets(_ store: any BatchedCensusBudgetStore, query: BatchedCensusBudgetQuery) -> [BatchedCensusBudget] {
        return query.apply(store.list())
    }
}
