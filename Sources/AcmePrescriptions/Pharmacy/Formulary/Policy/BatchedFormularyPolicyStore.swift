import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps batched formulary policies by code.
    protocol BatchedFormularyPolicyStore {
        func find(_ code: String) -> BatchedFormularyPolicy?
        func save(_ item: BatchedFormularyPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedFormularyPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedFormularyPolicyStore: BatchedFormularyPolicyStore {
        var items: [String: BatchedFormularyPolicy]
        var order: [String]

        init(items: [String: BatchedFormularyPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedFormularyPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedFormularyPolicy) {
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

        func list() -> [BatchedFormularyPolicy] {
            var out: [BatchedFormularyPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedFormularyPolicyStore() -> any BatchedFormularyPolicyStore {
        return MemoryBatchedFormularyPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedFormularyPolicyStore: BatchedFormularyPolicyStore {
        var inner: MemoryBatchedFormularyPolicyStore
        var cache: TTLCache<BatchedFormularyPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedFormularyPolicyStore, cache: TTLCache<BatchedFormularyPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedFormularyPolicy? {
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

        func save(_ item: BatchedFormularyPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedFormularyPolicy] {
            return inner.list()
        }
    }

    static func newCachedBatchedFormularyPolicyStore(_ inner: MemoryBatchedFormularyPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedFormularyPolicyStore {
        return CachedBatchedFormularyPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched formulary policies. Empty fields match all.
    final class BatchedFormularyPolicyQuery {
        var country: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedFormularyPolicy) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedFormularyPolicy]) -> [BatchedFormularyPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedFormularyPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedFormularyPolicies(_ store: any BatchedFormularyPolicyStore, query: BatchedFormularyPolicyQuery) -> [BatchedFormularyPolicy] {
        return query.apply(store.list())
    }
}
