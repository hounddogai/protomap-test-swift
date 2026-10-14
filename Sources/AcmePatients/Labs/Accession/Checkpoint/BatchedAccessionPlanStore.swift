import AcmePlatform
import Foundation

extension Labs {
    /// Keeps batched accession plans by code.
    protocol BatchedAccessionPlanStore {
        func find(_ code: String) -> BatchedAccessionPlan?
        func save(_ item: BatchedAccessionPlan)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedAccessionPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedAccessionPlanStore: BatchedAccessionPlanStore {
        var items: [String: BatchedAccessionPlan]
        var order: [String]

        init(items: [String: BatchedAccessionPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedAccessionPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedAccessionPlan) {
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

        func list() -> [BatchedAccessionPlan] {
            var out: [BatchedAccessionPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedAccessionPlanStore() -> any BatchedAccessionPlanStore {
        return MemoryBatchedAccessionPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedAccessionPlanStore: BatchedAccessionPlanStore {
        var inner: MemoryBatchedAccessionPlanStore
        var cache: TTLCache<BatchedAccessionPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedAccessionPlanStore, cache: TTLCache<BatchedAccessionPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedAccessionPlan? {
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

        func save(_ item: BatchedAccessionPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedAccessionPlan] {
            return inner.list()
        }
    }

    static func newCachedBatchedAccessionPlanStore(_ inner: MemoryBatchedAccessionPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedAccessionPlanStore {
        return CachedBatchedAccessionPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched accession plans. Empty fields match all.
    final class BatchedAccessionPlanQuery {
        var channel: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedAccessionPlan) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedAccessionPlan]) -> [BatchedAccessionPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedAccessionPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedAccessionPlans(_ store: any BatchedAccessionPlanStore, query: BatchedAccessionPlanQuery) -> [BatchedAccessionPlan] {
        return query.apply(store.list())
    }
}
