import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps batched transfer claims by code.
    protocol BatchedTransferClaimStore {
        func find(_ code: String) -> BatchedTransferClaim?
        func save(_ item: BatchedTransferClaim)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedTransferClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedTransferClaimStore: BatchedTransferClaimStore {
        var items: [String: BatchedTransferClaim]
        var order: [String]

        init(items: [String: BatchedTransferClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedTransferClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedTransferClaim) {
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

        func list() -> [BatchedTransferClaim] {
            var out: [BatchedTransferClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedTransferClaimStore() -> any BatchedTransferClaimStore {
        return MemoryBatchedTransferClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedTransferClaimStore: BatchedTransferClaimStore {
        var inner: MemoryBatchedTransferClaimStore
        var cache: TTLCache<BatchedTransferClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedTransferClaimStore, cache: TTLCache<BatchedTransferClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedTransferClaim? {
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

        func save(_ item: BatchedTransferClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedTransferClaim] {
            return inner.list()
        }
    }

    static func newCachedBatchedTransferClaimStore(_ inner: MemoryBatchedTransferClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedTransferClaimStore {
        return CachedBatchedTransferClaimStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched transfer claims. Empty fields match all.
    final class BatchedTransferClaimQuery {
        var region: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedTransferClaim) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedTransferClaim]) -> [BatchedTransferClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedTransferClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedTransferClaims(_ store: any BatchedTransferClaimStore, query: BatchedTransferClaimQuery) -> [BatchedTransferClaim] {
        return query.apply(store.list())
    }
}
