import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual care gap metrics by code.
    protocol ManualCareGapMetricStore {
        func find(_ code: String) -> ManualCareGapMetric?
        func save(_ item: ManualCareGapMetric)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCareGapMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCareGapMetricStore: ManualCareGapMetricStore {
        var items: [String: ManualCareGapMetric]
        var order: [String]

        init(items: [String: ManualCareGapMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCareGapMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCareGapMetric) {
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

        func list() -> [ManualCareGapMetric] {
            var out: [ManualCareGapMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCareGapMetricStore() -> any ManualCareGapMetricStore {
        return MemoryManualCareGapMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCareGapMetricStore: ManualCareGapMetricStore {
        var inner: MemoryManualCareGapMetricStore
        var cache: TTLCache<ManualCareGapMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCareGapMetricStore, cache: TTLCache<ManualCareGapMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCareGapMetric? {
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

        func save(_ item: ManualCareGapMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCareGapMetric] {
            return inner.list()
        }
    }

    static func newCachedManualCareGapMetricStore(_ inner: MemoryManualCareGapMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCareGapMetricStore {
        return CachedManualCareGapMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual care gap metrics. Empty fields match all.
    final class ManualCareGapMetricQuery {
        var region: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCareGapMetric) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualCareGapMetric]) -> [ManualCareGapMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCareGapMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCareGapMetrics(_ store: any ManualCareGapMetricStore, query: ManualCareGapMetricQuery) -> [ManualCareGapMetric] {
        return query.apply(store.list())
    }
}
