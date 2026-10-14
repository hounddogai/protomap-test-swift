import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps rolling study metrics by code.
    protocol RollingStudyMetricStore {
        func find(_ code: String) -> RollingStudyMetric?
        func save(_ item: RollingStudyMetric)
        func remove(_ code: String) -> Bool
        func list() -> [RollingStudyMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingStudyMetricStore: RollingStudyMetricStore {
        var items: [String: RollingStudyMetric]
        var order: [String]

        init(items: [String: RollingStudyMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingStudyMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingStudyMetric) {
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

        func list() -> [RollingStudyMetric] {
            var out: [RollingStudyMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingStudyMetricStore() -> any RollingStudyMetricStore {
        return MemoryRollingStudyMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingStudyMetricStore: RollingStudyMetricStore {
        var inner: MemoryRollingStudyMetricStore
        var cache: TTLCache<RollingStudyMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingStudyMetricStore, cache: TTLCache<RollingStudyMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingStudyMetric? {
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

        func save(_ item: RollingStudyMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingStudyMetric] {
            return inner.list()
        }
    }

    static func newCachedRollingStudyMetricStore(_ inner: MemoryRollingStudyMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingStudyMetricStore {
        return CachedRollingStudyMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling study metrics. Empty fields match all.
    final class RollingStudyMetricQuery {
        var unit: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingStudyMetric) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingStudyMetric]) -> [RollingStudyMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingStudyMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingStudyMetrics(_ store: any RollingStudyMetricStore, query: RollingStudyMetricQuery) -> [RollingStudyMetric] {
        return query.apply(store.list())
    }
}
