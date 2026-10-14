import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps batched read plans by code.
    protocol BatchedReadPlanStore {
        func find(_ code: String) -> BatchedReadPlan?
        func save(_ item: BatchedReadPlan)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedReadPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedReadPlanStore: BatchedReadPlanStore {
        var items: [String: BatchedReadPlan]
        var order: [String]

        init(items: [String: BatchedReadPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedReadPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedReadPlan) {
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

        func list() -> [BatchedReadPlan] {
            var out: [BatchedReadPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedReadPlanStore() -> any BatchedReadPlanStore {
        return MemoryBatchedReadPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedReadPlanStore: BatchedReadPlanStore {
        var inner: MemoryBatchedReadPlanStore
        var cache: TTLCache<BatchedReadPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedReadPlanStore, cache: TTLCache<BatchedReadPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedReadPlan? {
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

        func save(_ item: BatchedReadPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedReadPlan] {
            return inner.list()
        }
    }

    static func newCachedBatchedReadPlanStore(_ inner: MemoryBatchedReadPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedReadPlanStore {
        return CachedBatchedReadPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched read plans. Empty fields match all.
    final class BatchedReadPlanQuery {
        var country: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedReadPlan) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedReadPlan]) -> [BatchedReadPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedReadPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedReadPlans(_ store: any BatchedReadPlanStore, query: BatchedReadPlanQuery) -> [BatchedReadPlan] {
        return query.apply(store.list())
    }
}
