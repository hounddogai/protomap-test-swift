import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps batched referral rollups by code.
    protocol BatchedReferralRollupStore {
        func find(_ code: String) -> BatchedReferralRollup?
        func save(_ item: BatchedReferralRollup)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedReferralRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedReferralRollupStore: BatchedReferralRollupStore {
        var items: [String: BatchedReferralRollup]
        var order: [String]

        init(items: [String: BatchedReferralRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedReferralRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedReferralRollup) {
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

        func list() -> [BatchedReferralRollup] {
            var out: [BatchedReferralRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedReferralRollupStore() -> any BatchedReferralRollupStore {
        return MemoryBatchedReferralRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedReferralRollupStore: BatchedReferralRollupStore {
        var inner: MemoryBatchedReferralRollupStore
        var cache: TTLCache<BatchedReferralRollup>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedReferralRollupStore, cache: TTLCache<BatchedReferralRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedReferralRollup? {
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

        func save(_ item: BatchedReferralRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedReferralRollup] {
            return inner.list()
        }
    }

    static func newCachedBatchedReferralRollupStore(_ inner: MemoryBatchedReferralRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedReferralRollupStore {
        return CachedBatchedReferralRollupStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched referral rollups. Empty fields match all.
    final class BatchedReferralRollupQuery {
        var facility: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRetries: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedReferralRollup) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedReferralRollup]) -> [BatchedReferralRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedReferralRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedReferralRollups(_ store: any BatchedReferralRollupStore, query: BatchedReferralRollupQuery) -> [BatchedReferralRollup] {
        return query.apply(store.list())
    }
}
