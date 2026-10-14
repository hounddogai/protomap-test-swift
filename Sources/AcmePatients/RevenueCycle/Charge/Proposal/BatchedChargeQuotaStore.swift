import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps batched charge quotas by code.
    protocol BatchedChargeQuotaStore {
        func find(_ code: String) -> BatchedChargeQuota?
        func save(_ item: BatchedChargeQuota)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedChargeQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedChargeQuotaStore: BatchedChargeQuotaStore {
        var items: [String: BatchedChargeQuota]
        var order: [String]

        init(items: [String: BatchedChargeQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedChargeQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedChargeQuota) {
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

        func list() -> [BatchedChargeQuota] {
            var out: [BatchedChargeQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedChargeQuotaStore() -> any BatchedChargeQuotaStore {
        return MemoryBatchedChargeQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedChargeQuotaStore: BatchedChargeQuotaStore {
        var inner: MemoryBatchedChargeQuotaStore
        var cache: TTLCache<BatchedChargeQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedChargeQuotaStore, cache: TTLCache<BatchedChargeQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedChargeQuota? {
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

        func save(_ item: BatchedChargeQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedChargeQuota] {
            return inner.list()
        }
    }

    static func newCachedBatchedChargeQuotaStore(_ inner: MemoryBatchedChargeQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedChargeQuotaStore {
        return CachedBatchedChargeQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched charge quotas. Empty fields match all.
    final class BatchedChargeQuotaQuery {
        var source: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedChargeQuota) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedChargeQuota]) -> [BatchedChargeQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedChargeQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedChargeQuotas(_ store: any BatchedChargeQuotaStore, query: BatchedChargeQuotaQuery) -> [BatchedChargeQuota] {
        return query.apply(store.list())
    }
}
