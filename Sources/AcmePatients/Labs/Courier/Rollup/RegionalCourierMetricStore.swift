import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional courier metrics by code.
    protocol RegionalCourierMetricStore {
        func find(_ code: String) -> RegionalCourierMetric?
        func save(_ item: RegionalCourierMetric)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalCourierMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalCourierMetricStore: RegionalCourierMetricStore {
        var items: [String: RegionalCourierMetric]
        var order: [String]

        init(items: [String: RegionalCourierMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalCourierMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalCourierMetric) {
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

        func list() -> [RegionalCourierMetric] {
            var out: [RegionalCourierMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalCourierMetricStore() -> any RegionalCourierMetricStore {
        return MemoryRegionalCourierMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalCourierMetricStore: RegionalCourierMetricStore {
        var inner: MemoryRegionalCourierMetricStore
        var cache: TTLCache<RegionalCourierMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalCourierMetricStore, cache: TTLCache<RegionalCourierMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalCourierMetric? {
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

        func save(_ item: RegionalCourierMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalCourierMetric] {
            return inner.list()
        }
    }

    static func newCachedRegionalCourierMetricStore(_ inner: MemoryRegionalCourierMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalCourierMetricStore {
        return CachedRegionalCourierMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional courier metrics. Empty fields match all.
    final class RegionalCourierMetricQuery {
        var category: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalCourierMetric) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalCourierMetric]) -> [RegionalCourierMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalCourierMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalCourierMetrics(_ store: any RegionalCourierMetricStore, query: RegionalCourierMetricQuery) -> [RegionalCourierMetric] {
        return query.apply(store.list())
    }
}
