import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps batched network claims by code.
    protocol BatchedNetworkClaimStore {
        func find(_ code: String) -> BatchedNetworkClaim?
        func save(_ item: BatchedNetworkClaim)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedNetworkClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedNetworkClaimStore: BatchedNetworkClaimStore {
        var items: [String: BatchedNetworkClaim]
        var order: [String]

        init(items: [String: BatchedNetworkClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedNetworkClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedNetworkClaim) {
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

        func list() -> [BatchedNetworkClaim] {
            var out: [BatchedNetworkClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedNetworkClaimStore() -> any BatchedNetworkClaimStore {
        return MemoryBatchedNetworkClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedNetworkClaimStore: BatchedNetworkClaimStore {
        var inner: MemoryBatchedNetworkClaimStore
        var cache: TTLCache<BatchedNetworkClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedNetworkClaimStore, cache: TTLCache<BatchedNetworkClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedNetworkClaim? {
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

        func save(_ item: BatchedNetworkClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedNetworkClaim] {
            return inner.list()
        }
    }

    static func newCachedBatchedNetworkClaimStore(_ inner: MemoryBatchedNetworkClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedNetworkClaimStore {
        return CachedBatchedNetworkClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched network claims. Empty fields match all.
    final class BatchedNetworkClaimQuery {
        var unit: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minBudget: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedNetworkClaim) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedNetworkClaim]) -> [BatchedNetworkClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedNetworkClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedNetworkClaims(_ store: any BatchedNetworkClaimStore, query: BatchedNetworkClaimQuery) -> [BatchedNetworkClaim] {
        return query.apply(store.list())
    }
}
