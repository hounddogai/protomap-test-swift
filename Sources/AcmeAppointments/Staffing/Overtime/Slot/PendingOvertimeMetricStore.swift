import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps pending overtime metrics by code.
    protocol PendingOvertimeMetricStore {
        func find(_ code: String) -> PendingOvertimeMetric?
        func save(_ item: PendingOvertimeMetric)
        func remove(_ code: String) -> Bool
        func list() -> [PendingOvertimeMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingOvertimeMetricStore: PendingOvertimeMetricStore {
        var items: [String: PendingOvertimeMetric]
        var order: [String]

        init(items: [String: PendingOvertimeMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingOvertimeMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingOvertimeMetric) {
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

        func list() -> [PendingOvertimeMetric] {
            var out: [PendingOvertimeMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingOvertimeMetricStore() -> any PendingOvertimeMetricStore {
        return MemoryPendingOvertimeMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingOvertimeMetricStore: PendingOvertimeMetricStore {
        var inner: MemoryPendingOvertimeMetricStore
        var cache: TTLCache<PendingOvertimeMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingOvertimeMetricStore, cache: TTLCache<PendingOvertimeMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingOvertimeMetric? {
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

        func save(_ item: PendingOvertimeMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingOvertimeMetric] {
            return inner.list()
        }
    }

    static func newCachedPendingOvertimeMetricStore(_ inner: MemoryPendingOvertimeMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingOvertimeMetricStore {
        return CachedPendingOvertimeMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending overtime metrics. Empty fields match all.
    final class PendingOvertimeMetricQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingOvertimeMetric) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingOvertimeMetric]) -> [PendingOvertimeMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingOvertimeMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingOvertimeMetrics(_ store: any PendingOvertimeMetricStore, query: PendingOvertimeMetricQuery) -> [PendingOvertimeMetric] {
        return query.apply(store.list())
    }
}
