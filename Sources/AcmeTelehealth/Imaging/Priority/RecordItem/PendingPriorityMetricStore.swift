import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending priority metrics by code.
    protocol PendingPriorityMetricStore {
        func find(_ code: String) -> PendingPriorityMetric?
        func save(_ item: PendingPriorityMetric)
        func remove(_ code: String) -> Bool
        func list() -> [PendingPriorityMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingPriorityMetricStore: PendingPriorityMetricStore {
        var items: [String: PendingPriorityMetric]
        var order: [String]

        init(items: [String: PendingPriorityMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingPriorityMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingPriorityMetric) {
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

        func list() -> [PendingPriorityMetric] {
            var out: [PendingPriorityMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingPriorityMetricStore() -> any PendingPriorityMetricStore {
        return MemoryPendingPriorityMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingPriorityMetricStore: PendingPriorityMetricStore {
        var inner: MemoryPendingPriorityMetricStore
        var cache: TTLCache<PendingPriorityMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingPriorityMetricStore, cache: TTLCache<PendingPriorityMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingPriorityMetric? {
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

        func save(_ item: PendingPriorityMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingPriorityMetric] {
            return inner.list()
        }
    }

    static func newCachedPendingPriorityMetricStore(_ inner: MemoryPendingPriorityMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingPriorityMetricStore {
        return CachedPendingPriorityMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending priority metrics. Empty fields match all.
    final class PendingPriorityMetricQuery {
        var unit: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingPriorityMetric) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [PendingPriorityMetric]) -> [PendingPriorityMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingPriorityMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingPriorityMetrics(_ store: any PendingPriorityMetricStore, query: PendingPriorityMetricQuery) -> [PendingPriorityMetric] {
        return query.apply(store.list())
    }
}
