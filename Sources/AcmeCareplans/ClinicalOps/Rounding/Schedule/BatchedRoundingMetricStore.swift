import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps batched rounding metrics by code.
    protocol BatchedRoundingMetricStore {
        func find(_ code: String) -> BatchedRoundingMetric?
        func save(_ item: BatchedRoundingMetric)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedRoundingMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedRoundingMetricStore: BatchedRoundingMetricStore {
        var items: [String: BatchedRoundingMetric]
        var order: [String]

        init(items: [String: BatchedRoundingMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedRoundingMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedRoundingMetric) {
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

        func list() -> [BatchedRoundingMetric] {
            var out: [BatchedRoundingMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedRoundingMetricStore() -> any BatchedRoundingMetricStore {
        return MemoryBatchedRoundingMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedRoundingMetricStore: BatchedRoundingMetricStore {
        var inner: MemoryBatchedRoundingMetricStore
        var cache: TTLCache<BatchedRoundingMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedRoundingMetricStore, cache: TTLCache<BatchedRoundingMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedRoundingMetric? {
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

        func save(_ item: BatchedRoundingMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedRoundingMetric] {
            return inner.list()
        }
    }

    static func newCachedBatchedRoundingMetricStore(_ inner: MemoryBatchedRoundingMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedRoundingMetricStore {
        return CachedBatchedRoundingMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched rounding metrics. Empty fields match all.
    final class BatchedRoundingMetricQuery {
        var label: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVersion: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedRoundingMetric) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedRoundingMetric]) -> [BatchedRoundingMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedRoundingMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedRoundingMetrics(_ store: any BatchedRoundingMetricStore, query: BatchedRoundingMetricQuery) -> [BatchedRoundingMetric] {
        return query.apply(store.list())
    }
}
