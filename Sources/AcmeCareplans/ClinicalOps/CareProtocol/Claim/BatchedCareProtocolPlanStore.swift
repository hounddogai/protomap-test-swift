import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps batched care protocol plans by code.
    protocol BatchedCareProtocolPlanStore {
        func find(_ code: String) -> BatchedCareProtocolPlan?
        func save(_ item: BatchedCareProtocolPlan)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCareProtocolPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCareProtocolPlanStore: BatchedCareProtocolPlanStore {
        var items: [String: BatchedCareProtocolPlan]
        var order: [String]

        init(items: [String: BatchedCareProtocolPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCareProtocolPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCareProtocolPlan) {
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

        func list() -> [BatchedCareProtocolPlan] {
            var out: [BatchedCareProtocolPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCareProtocolPlanStore() -> any BatchedCareProtocolPlanStore {
        return MemoryBatchedCareProtocolPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCareProtocolPlanStore: BatchedCareProtocolPlanStore {
        var inner: MemoryBatchedCareProtocolPlanStore
        var cache: TTLCache<BatchedCareProtocolPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCareProtocolPlanStore, cache: TTLCache<BatchedCareProtocolPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCareProtocolPlan? {
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

        func save(_ item: BatchedCareProtocolPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCareProtocolPlan] {
            return inner.list()
        }
    }

    static func newCachedBatchedCareProtocolPlanStore(_ inner: MemoryBatchedCareProtocolPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCareProtocolPlanStore {
        return CachedBatchedCareProtocolPlanStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched care protocol plans. Empty fields match all.
    final class BatchedCareProtocolPlanQuery {
        var channel: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minSequence: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCareProtocolPlan) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedCareProtocolPlan]) -> [BatchedCareProtocolPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCareProtocolPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCareProtocolPlans(_ store: any BatchedCareProtocolPlanStore, query: BatchedCareProtocolPlanQuery) -> [BatchedCareProtocolPlan] {
        return query.apply(store.list())
    }
}
