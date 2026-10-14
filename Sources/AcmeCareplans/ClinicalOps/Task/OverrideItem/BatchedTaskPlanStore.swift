import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps batched task plans by code.
    protocol BatchedTaskPlanStore {
        func find(_ code: String) -> BatchedTaskPlan?
        func save(_ item: BatchedTaskPlan)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedTaskPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedTaskPlanStore: BatchedTaskPlanStore {
        var items: [String: BatchedTaskPlan]
        var order: [String]

        init(items: [String: BatchedTaskPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedTaskPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedTaskPlan) {
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

        func list() -> [BatchedTaskPlan] {
            var out: [BatchedTaskPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedTaskPlanStore() -> any BatchedTaskPlanStore {
        return MemoryBatchedTaskPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedTaskPlanStore: BatchedTaskPlanStore {
        var inner: MemoryBatchedTaskPlanStore
        var cache: TTLCache<BatchedTaskPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedTaskPlanStore, cache: TTLCache<BatchedTaskPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedTaskPlan? {
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

        func save(_ item: BatchedTaskPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedTaskPlan] {
            return inner.list()
        }
    }

    static func newCachedBatchedTaskPlanStore(_ inner: MemoryBatchedTaskPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedTaskPlanStore {
        return CachedBatchedTaskPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched task plans. Empty fields match all.
    final class BatchedTaskPlanQuery {
        var label: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minWeight: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedTaskPlan) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedTaskPlan]) -> [BatchedTaskPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedTaskPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedTaskPlans(_ store: any BatchedTaskPlanStore, query: BatchedTaskPlanQuery) -> [BatchedTaskPlan] {
        return query.apply(store.list())
    }
}
