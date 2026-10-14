import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps batched slot quotas by code.
    protocol BatchedSlotQuotaStore {
        func find(_ code: String) -> BatchedSlotQuota?
        func save(_ item: BatchedSlotQuota)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedSlotQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedSlotQuotaStore: BatchedSlotQuotaStore {
        var items: [String: BatchedSlotQuota]
        var order: [String]

        init(items: [String: BatchedSlotQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedSlotQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedSlotQuota) {
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

        func list() -> [BatchedSlotQuota] {
            var out: [BatchedSlotQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedSlotQuotaStore() -> any BatchedSlotQuotaStore {
        return MemoryBatchedSlotQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedSlotQuotaStore: BatchedSlotQuotaStore {
        var inner: MemoryBatchedSlotQuotaStore
        var cache: TTLCache<BatchedSlotQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedSlotQuotaStore, cache: TTLCache<BatchedSlotQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedSlotQuota? {
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

        func save(_ item: BatchedSlotQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedSlotQuota] {
            return inner.list()
        }
    }

    static func newCachedBatchedSlotQuotaStore(_ inner: MemoryBatchedSlotQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedSlotQuotaStore {
        return CachedBatchedSlotQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched slot quotas. Empty fields match all.
    final class BatchedSlotQuotaQuery {
        var country: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minScore: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedSlotQuota) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedSlotQuota]) -> [BatchedSlotQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedSlotQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedSlotQuotas(_ store: any BatchedSlotQuotaStore, query: BatchedSlotQuotaQuery) -> [BatchedSlotQuota] {
        return query.apply(store.list())
    }
}
