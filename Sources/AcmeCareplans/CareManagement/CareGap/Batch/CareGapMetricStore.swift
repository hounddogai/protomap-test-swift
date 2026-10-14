import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps care gap metrics by code.
    protocol CareGapMetricStore {
        func find(_ code: String) -> CareGapMetric?
        func save(_ item: CareGapMetric)
        func remove(_ code: String) -> Bool
        func list() -> [CareGapMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareGapMetricStore: CareGapMetricStore {
        var items: [String: CareGapMetric]
        var order: [String]

        init(items: [String: CareGapMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareGapMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareGapMetric) {
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

        func list() -> [CareGapMetric] {
            var out: [CareGapMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareGapMetricStore() -> any CareGapMetricStore {
        return MemoryCareGapMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareGapMetricStore: CareGapMetricStore {
        var inner: MemoryCareGapMetricStore
        var cache: TTLCache<CareGapMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareGapMetricStore, cache: TTLCache<CareGapMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareGapMetric? {
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

        func save(_ item: CareGapMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareGapMetric] {
            return inner.list()
        }
    }

    static func newCachedCareGapMetricStore(_ inner: MemoryCareGapMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareGapMetricStore {
        return CachedCareGapMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care gap metrics. Empty fields match all.
    final class CareGapMetricQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareGapMetric) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [CareGapMetric]) -> [CareGapMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareGapMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareGapMetrics(_ store: any CareGapMetricStore, query: CareGapMetricQuery) -> [CareGapMetric] {
        return query.apply(store.list())
    }
}
