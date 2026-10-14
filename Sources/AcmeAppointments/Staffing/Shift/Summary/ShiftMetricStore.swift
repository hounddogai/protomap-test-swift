import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift metrics by code.
    protocol ShiftMetricStore {
        func find(_ code: String) -> ShiftMetric?
        func save(_ item: ShiftMetric)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftMetricStore: ShiftMetricStore {
        var items: [String: ShiftMetric]
        var order: [String]

        init(items: [String: ShiftMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftMetric) {
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

        func list() -> [ShiftMetric] {
            var out: [ShiftMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftMetricStore() -> any ShiftMetricStore {
        return MemoryShiftMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftMetricStore: ShiftMetricStore {
        var inner: MemoryShiftMetricStore
        var cache: TTLCache<ShiftMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftMetricStore, cache: TTLCache<ShiftMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftMetric? {
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

        func save(_ item: ShiftMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftMetric] {
            return inner.list()
        }
    }

    static func newCachedShiftMetricStore(_ inner: MemoryShiftMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftMetricStore {
        return CachedShiftMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift metrics. Empty fields match all.
    final class ShiftMetricQuery {
        var region: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftMetric) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ShiftMetric]) -> [ShiftMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftMetrics(_ store: any ShiftMetricStore, query: ShiftMetricQuery) -> [ShiftMetric] {
        return query.apply(store.list())
    }
}
