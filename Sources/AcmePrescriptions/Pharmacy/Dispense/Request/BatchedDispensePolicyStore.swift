import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps batched dispense policies by code.
    protocol BatchedDispensePolicyStore {
        func find(_ code: String) -> BatchedDispensePolicy?
        func save(_ item: BatchedDispensePolicy)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedDispensePolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedDispensePolicyStore: BatchedDispensePolicyStore {
        var items: [String: BatchedDispensePolicy]
        var order: [String]

        init(items: [String: BatchedDispensePolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedDispensePolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedDispensePolicy) {
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

        func list() -> [BatchedDispensePolicy] {
            var out: [BatchedDispensePolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedDispensePolicyStore() -> any BatchedDispensePolicyStore {
        return MemoryBatchedDispensePolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedDispensePolicyStore: BatchedDispensePolicyStore {
        var inner: MemoryBatchedDispensePolicyStore
        var cache: TTLCache<BatchedDispensePolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedDispensePolicyStore, cache: TTLCache<BatchedDispensePolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedDispensePolicy? {
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

        func save(_ item: BatchedDispensePolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedDispensePolicy] {
            return inner.list()
        }
    }

    static func newCachedBatchedDispensePolicyStore(_ inner: MemoryBatchedDispensePolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedDispensePolicyStore {
        return CachedBatchedDispensePolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched dispense policies. Empty fields match all.
    final class BatchedDispensePolicyQuery {
        var title: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCost: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedDispensePolicy) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedDispensePolicy]) -> [BatchedDispensePolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedDispensePolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedDispensePolicies(_ store: any BatchedDispensePolicyStore, query: BatchedDispensePolicyQuery) -> [BatchedDispensePolicy] {
        return query.apply(store.list())
    }
}
