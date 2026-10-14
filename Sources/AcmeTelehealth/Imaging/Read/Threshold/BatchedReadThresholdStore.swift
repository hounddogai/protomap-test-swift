import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps batched read thresholds by code.
    protocol BatchedReadThresholdStore {
        func find(_ code: String) -> BatchedReadThreshold?
        func save(_ item: BatchedReadThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedReadThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedReadThresholdStore: BatchedReadThresholdStore {
        var items: [String: BatchedReadThreshold]
        var order: [String]

        init(items: [String: BatchedReadThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedReadThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedReadThreshold) {
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

        func list() -> [BatchedReadThreshold] {
            var out: [BatchedReadThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedReadThresholdStore() -> any BatchedReadThresholdStore {
        return MemoryBatchedReadThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedReadThresholdStore: BatchedReadThresholdStore {
        var inner: MemoryBatchedReadThresholdStore
        var cache: TTLCache<BatchedReadThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedReadThresholdStore, cache: TTLCache<BatchedReadThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedReadThreshold? {
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

        func save(_ item: BatchedReadThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedReadThreshold] {
            return inner.list()
        }
    }

    static func newCachedBatchedReadThresholdStore(_ inner: MemoryBatchedReadThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedReadThresholdStore {
        return CachedBatchedReadThresholdStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched read thresholds. Empty fields match all.
    final class BatchedReadThresholdQuery {
        var title: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRate: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedReadThreshold) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedReadThreshold]) -> [BatchedReadThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedReadThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedReadThresholds(_ store: any BatchedReadThresholdStore, query: BatchedReadThresholdQuery) -> [BatchedReadThreshold] {
        return query.apply(store.list())
    }
}
