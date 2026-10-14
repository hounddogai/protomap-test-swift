import AcmePlatform
import Foundation

extension Consent {
    /// Keeps batched witness quotas by code.
    protocol BatchedWitnessQuotaStore {
        func find(_ code: String) -> BatchedWitnessQuota?
        func save(_ item: BatchedWitnessQuota)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedWitnessQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedWitnessQuotaStore: BatchedWitnessQuotaStore {
        var items: [String: BatchedWitnessQuota]
        var order: [String]

        init(items: [String: BatchedWitnessQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedWitnessQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedWitnessQuota) {
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

        func list() -> [BatchedWitnessQuota] {
            var out: [BatchedWitnessQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedWitnessQuotaStore() -> any BatchedWitnessQuotaStore {
        return MemoryBatchedWitnessQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedWitnessQuotaStore: BatchedWitnessQuotaStore {
        var inner: MemoryBatchedWitnessQuotaStore
        var cache: TTLCache<BatchedWitnessQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedWitnessQuotaStore, cache: TTLCache<BatchedWitnessQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedWitnessQuota? {
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

        func save(_ item: BatchedWitnessQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedWitnessQuota] {
            return inner.list()
        }
    }

    static func newCachedBatchedWitnessQuotaStore(_ inner: MemoryBatchedWitnessQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedWitnessQuotaStore {
        return CachedBatchedWitnessQuotaStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched witness quotas. Empty fields match all.
    final class BatchedWitnessQuotaQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedWitnessQuota) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedWitnessQuota]) -> [BatchedWitnessQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedWitnessQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedWitnessQuotas(_ store: any BatchedWitnessQuotaStore, query: BatchedWitnessQuotaQuery) -> [BatchedWitnessQuota] {
        return query.apply(store.list())
    }
}
