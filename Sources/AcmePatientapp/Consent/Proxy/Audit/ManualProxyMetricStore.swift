import AcmePlatform
import Foundation

extension Consent {
    /// Keeps manual proxy metrics by code.
    protocol ManualProxyMetricStore {
        func find(_ code: String) -> ManualProxyMetric?
        func save(_ item: ManualProxyMetric)
        func remove(_ code: String) -> Bool
        func list() -> [ManualProxyMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualProxyMetricStore: ManualProxyMetricStore {
        var items: [String: ManualProxyMetric]
        var order: [String]

        init(items: [String: ManualProxyMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualProxyMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualProxyMetric) {
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

        func list() -> [ManualProxyMetric] {
            var out: [ManualProxyMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualProxyMetricStore() -> any ManualProxyMetricStore {
        return MemoryManualProxyMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualProxyMetricStore: ManualProxyMetricStore {
        var inner: MemoryManualProxyMetricStore
        var cache: TTLCache<ManualProxyMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualProxyMetricStore, cache: TTLCache<ManualProxyMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualProxyMetric? {
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

        func save(_ item: ManualProxyMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualProxyMetric] {
            return inner.list()
        }
    }

    static func newCachedManualProxyMetricStore(_ inner: MemoryManualProxyMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualProxyMetricStore {
        return CachedManualProxyMetricStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual proxy metrics. Empty fields match all.
    final class ManualProxyMetricQuery {
        var facility: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minRevision: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualProxyMetric) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualProxyMetric]) -> [ManualProxyMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualProxyMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualProxyMetrics(_ store: any ManualProxyMetricStore, query: ManualProxyMetricQuery) -> [ManualProxyMetric] {
        return query.apply(store.list())
    }
}
