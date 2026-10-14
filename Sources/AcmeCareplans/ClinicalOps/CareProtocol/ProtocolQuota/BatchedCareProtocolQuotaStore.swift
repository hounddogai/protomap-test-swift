import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps batched care protocol quotas by code.
    protocol BatchedCareProtocolQuotaStore {
        func find(_ code: String) -> BatchedCareProtocolQuota?
        func save(_ item: BatchedCareProtocolQuota)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCareProtocolQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCareProtocolQuotaStore: BatchedCareProtocolQuotaStore {
        var items: [String: BatchedCareProtocolQuota]
        var order: [String]

        init(items: [String: BatchedCareProtocolQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCareProtocolQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCareProtocolQuota) {
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

        func list() -> [BatchedCareProtocolQuota] {
            var out: [BatchedCareProtocolQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCareProtocolQuotaStore() -> any BatchedCareProtocolQuotaStore {
        return MemoryBatchedCareProtocolQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCareProtocolQuotaStore: BatchedCareProtocolQuotaStore {
        var inner: MemoryBatchedCareProtocolQuotaStore
        var cache: TTLCache<BatchedCareProtocolQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCareProtocolQuotaStore, cache: TTLCache<BatchedCareProtocolQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCareProtocolQuota? {
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

        func save(_ item: BatchedCareProtocolQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCareProtocolQuota] {
            return inner.list()
        }
    }

    static func newCachedBatchedCareProtocolQuotaStore(_ inner: MemoryBatchedCareProtocolQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCareProtocolQuotaStore {
        return CachedBatchedCareProtocolQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched care protocol quotas. Empty fields match all.
    final class BatchedCareProtocolQuotaQuery {
        var category: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCareProtocolQuota) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedCareProtocolQuota]) -> [BatchedCareProtocolQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCareProtocolQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCareProtocolQuotas(_ store: any BatchedCareProtocolQuotaStore, query: BatchedCareProtocolQuotaQuery) -> [BatchedCareProtocolQuota] {
        return query.apply(store.list())
    }
}
