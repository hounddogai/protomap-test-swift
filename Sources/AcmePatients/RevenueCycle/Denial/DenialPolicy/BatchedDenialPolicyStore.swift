import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched denial policies by code.
    protocol BatchedDenialPolicyStore {
        func find(_ code: String) -> BatchedDenialPolicy?
        func save(_ item: BatchedDenialPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedDenialPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedDenialPolicyStore: BatchedDenialPolicyStore {
        var items: [String: BatchedDenialPolicy]
        var order: [String]

        init(items: [String: BatchedDenialPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedDenialPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedDenialPolicy) {
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

        func list() -> [BatchedDenialPolicy] {
            var out: [BatchedDenialPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedDenialPolicyStore() -> any BatchedDenialPolicyStore {
        return MemoryBatchedDenialPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedDenialPolicyStore: BatchedDenialPolicyStore {
        var inner: MemoryBatchedDenialPolicyStore
        var cache: TTLCache<BatchedDenialPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedDenialPolicyStore, cache: TTLCache<BatchedDenialPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedDenialPolicy? {
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

        func save(_ item: BatchedDenialPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedDenialPolicy] {
            return inner.list()
        }
    }

    static func newCachedBatchedDenialPolicyStore(_ inner: MemoryBatchedDenialPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedDenialPolicyStore {
        return CachedBatchedDenialPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched denial policies. Empty fields match all.
    final class BatchedDenialPolicyQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedDenialPolicy) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [BatchedDenialPolicy]) -> [BatchedDenialPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedDenialPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedDenialPolicies(_ store: any BatchedDenialPolicyStore, query: BatchedDenialPolicyQuery) -> [BatchedDenialPolicy] {
        return query.apply(store.list())
    }
}
