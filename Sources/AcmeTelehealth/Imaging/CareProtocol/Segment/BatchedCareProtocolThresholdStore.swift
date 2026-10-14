import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps batched care protocol thresholds by code.
    protocol BatchedCareProtocolThresholdStore {
        func find(_ code: String) -> BatchedCareProtocolThreshold?
        func save(_ item: BatchedCareProtocolThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedCareProtocolThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedCareProtocolThresholdStore: BatchedCareProtocolThresholdStore {
        var items: [String: BatchedCareProtocolThreshold]
        var order: [String]

        init(items: [String: BatchedCareProtocolThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedCareProtocolThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedCareProtocolThreshold) {
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

        func list() -> [BatchedCareProtocolThreshold] {
            var out: [BatchedCareProtocolThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedCareProtocolThresholdStore() -> any BatchedCareProtocolThresholdStore {
        return MemoryBatchedCareProtocolThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedCareProtocolThresholdStore: BatchedCareProtocolThresholdStore {
        var inner: MemoryBatchedCareProtocolThresholdStore
        var cache: TTLCache<BatchedCareProtocolThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedCareProtocolThresholdStore, cache: TTLCache<BatchedCareProtocolThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedCareProtocolThreshold? {
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

        func save(_ item: BatchedCareProtocolThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedCareProtocolThreshold] {
            return inner.list()
        }
    }

    static func newCachedBatchedCareProtocolThresholdStore(_ inner: MemoryBatchedCareProtocolThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedCareProtocolThresholdStore {
        return CachedBatchedCareProtocolThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched care protocol thresholds. Empty fields match all.
    final class BatchedCareProtocolThresholdQuery {
        var segment: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedCareProtocolThreshold) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [BatchedCareProtocolThreshold]) -> [BatchedCareProtocolThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedCareProtocolThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedCareProtocolThresholds(_ store: any BatchedCareProtocolThresholdStore, query: BatchedCareProtocolThresholdQuery) -> [BatchedCareProtocolThreshold] {
        return query.apply(store.list())
    }
}
