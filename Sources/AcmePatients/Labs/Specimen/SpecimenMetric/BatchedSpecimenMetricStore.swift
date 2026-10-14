import AcmePlatform
import Foundation

extension Labs {
    /// Keeps batched specimen metrics by code.
    protocol BatchedSpecimenMetricStore {
        func find(_ code: String) -> BatchedSpecimenMetric?
        func save(_ item: BatchedSpecimenMetric)
        func remove(_ code: String) -> Bool
        func list() -> [BatchedSpecimenMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBatchedSpecimenMetricStore: BatchedSpecimenMetricStore {
        var items: [String: BatchedSpecimenMetric]
        var order: [String]

        init(items: [String: BatchedSpecimenMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BatchedSpecimenMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BatchedSpecimenMetric) {
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

        func list() -> [BatchedSpecimenMetric] {
            var out: [BatchedSpecimenMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBatchedSpecimenMetricStore() -> any BatchedSpecimenMetricStore {
        return MemoryBatchedSpecimenMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBatchedSpecimenMetricStore: BatchedSpecimenMetricStore {
        var inner: MemoryBatchedSpecimenMetricStore
        var cache: TTLCache<BatchedSpecimenMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryBatchedSpecimenMetricStore, cache: TTLCache<BatchedSpecimenMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BatchedSpecimenMetric? {
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

        func save(_ item: BatchedSpecimenMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BatchedSpecimenMetric] {
            return inner.list()
        }
    }

    static func newCachedBatchedSpecimenMetricStore(_ inner: MemoryBatchedSpecimenMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BatchedSpecimenMetricStore {
        return CachedBatchedSpecimenMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects batched specimen metrics. Empty fields match all.
    final class BatchedSpecimenMetricQuery {
        var facility: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minLimit: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BatchedSpecimenMetric) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BatchedSpecimenMetric]) -> [BatchedSpecimenMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BatchedSpecimenMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBatchedSpecimenMetrics(_ store: any BatchedSpecimenMetricStore, query: BatchedSpecimenMetricQuery) -> [BatchedSpecimenMetric] {
        return query.apply(store.list())
    }
}
