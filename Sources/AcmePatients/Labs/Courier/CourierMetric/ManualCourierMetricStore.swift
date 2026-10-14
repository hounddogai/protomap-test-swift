import AcmePlatform
import Foundation

extension Labs {
    /// Keeps manual courier metrics by code.
    protocol ManualCourierMetricStore {
        func find(_ code: String) -> ManualCourierMetric?
        func save(_ item: ManualCourierMetric)
        func remove(_ code: String) -> Bool
        func list() -> [ManualCourierMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualCourierMetricStore: ManualCourierMetricStore {
        var items: [String: ManualCourierMetric]
        var order: [String]

        init(items: [String: ManualCourierMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualCourierMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualCourierMetric) {
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

        func list() -> [ManualCourierMetric] {
            var out: [ManualCourierMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualCourierMetricStore() -> any ManualCourierMetricStore {
        return MemoryManualCourierMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualCourierMetricStore: ManualCourierMetricStore {
        var inner: MemoryManualCourierMetricStore
        var cache: TTLCache<ManualCourierMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualCourierMetricStore, cache: TTLCache<ManualCourierMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualCourierMetric? {
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

        func save(_ item: ManualCourierMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualCourierMetric] {
            return inner.list()
        }
    }

    static func newCachedManualCourierMetricStore(_ inner: MemoryManualCourierMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualCourierMetricStore {
        return CachedManualCourierMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual courier metrics. Empty fields match all.
    final class ManualCourierMetricQuery {
        var title: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualCourierMetric) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualCourierMetric]) -> [ManualCourierMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualCourierMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualCourierMetrics(_ store: any ManualCourierMetricStore, query: ManualCourierMetricQuery) -> [ManualCourierMetric] {
        return query.apply(store.list())
    }
}
