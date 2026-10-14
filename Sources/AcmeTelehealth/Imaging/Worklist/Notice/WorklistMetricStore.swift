import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist metrics by code.
    protocol WorklistMetricStore {
        func find(_ code: String) -> WorklistMetric?
        func save(_ item: WorklistMetric)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistMetricStore: WorklistMetricStore {
        var items: [String: WorklistMetric]
        var order: [String]

        init(items: [String: WorklistMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistMetric) {
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

        func list() -> [WorklistMetric] {
            var out: [WorklistMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistMetricStore() -> any WorklistMetricStore {
        return MemoryWorklistMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistMetricStore: WorklistMetricStore {
        var inner: MemoryWorklistMetricStore
        var cache: TTLCache<WorklistMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistMetricStore, cache: TTLCache<WorklistMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistMetric? {
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

        func save(_ item: WorklistMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistMetric] {
            return inner.list()
        }
    }

    static func newCachedWorklistMetricStore(_ inner: MemoryWorklistMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistMetricStore {
        return CachedWorklistMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist metrics. Empty fields match all.
    final class WorklistMetricQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistMetric) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistMetric]) -> [WorklistMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistMetrics(_ store: any WorklistMetricStore, query: WorklistMetricQuery) -> [WorklistMetric] {
        return query.apply(store.list())
    }
}
