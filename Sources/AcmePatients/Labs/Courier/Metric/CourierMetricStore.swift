import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier metrics by code.
    protocol CourierMetricStore {
        func find(_ code: String) -> CourierMetric?
        func save(_ item: CourierMetric)
        func remove(_ code: String) -> Bool
        func list() -> [CourierMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierMetricStore: CourierMetricStore {
        var items: [String: CourierMetric]
        var order: [String]

        init(items: [String: CourierMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierMetric) {
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

        func list() -> [CourierMetric] {
            var out: [CourierMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierMetricStore() -> any CourierMetricStore {
        return MemoryCourierMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierMetricStore: CourierMetricStore {
        var inner: MemoryCourierMetricStore
        var cache: TTLCache<CourierMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierMetricStore, cache: TTLCache<CourierMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierMetric? {
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

        func save(_ item: CourierMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierMetric] {
            return inner.list()
        }
    }

    static func newCachedCourierMetricStore(_ inner: MemoryCourierMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierMetricStore {
        return CachedCourierMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier metrics. Empty fields match all.
    final class CourierMetricQuery {
        var label: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minRevision: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierMetric) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [CourierMetric]) -> [CourierMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierMetrics(_ store: any CourierMetricStore, query: CourierMetricQuery) -> [CourierMetric] {
        return query.apply(store.list())
    }
}
