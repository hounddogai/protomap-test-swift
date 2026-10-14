import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps batched outreach policies by code.
    protocol BatchedOutreachPolicyStore {
        func find(_ code: String) -> BatchedOutreachPolicy?
        func save(_ item: BatchedOutreachPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedOutreachPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedOutreachPolicyStore: BatchedOutreachPolicyStore {
        var items: [String: BatchedOutreachPolicy]
        var order: [String]

        init(items: [String: BatchedOutreachPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedOutreachPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedOutreachPolicy) {
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

        func list() -> [BatchedOutreachPolicy] {
            var out: [BatchedOutreachPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedOutreachPolicyStore() -> any BatchedOutreachPolicyStore {
        return MemoryBatchedOutreachPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedOutreachPolicyStore: BatchedOutreachPolicyStore {
        var inner: MemoryBatchedOutreachPolicyStore
        var cache: TTLCache<BatchedOutreachPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedOutreachPolicyStore, cache: TTLCache<BatchedOutreachPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedOutreachPolicy? {
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

        func save(_ item: BatchedOutreachPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedOutreachPolicy] {
            return inner.list()
        }
    }

    static func newCachedBatchedOutreachPolicyStore(_ inner: MemoryBatchedOutreachPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedOutreachPolicyStore {
        return CachedBatchedOutreachPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched outreach policies. Empty fields match all.
    final class BatchedOutreachPolicyQuery {
        var name: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedOutreachPolicy) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedOutreachPolicy]) -> [BatchedOutreachPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedOutreachPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedOutreachPolicies(_ store: any BatchedOutreachPolicyStore, query: BatchedOutreachPolicyQuery) -> [BatchedOutreachPolicy] {
        return query.apply(store.list())
    }
}
