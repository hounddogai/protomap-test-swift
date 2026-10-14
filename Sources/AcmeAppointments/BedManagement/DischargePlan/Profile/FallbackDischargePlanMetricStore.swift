import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps fallback discharge plan metrics by code.
    protocol FallbackDischargePlanMetricStore {
        func find(_ code: String) -> FallbackDischargePlanMetric?
        func save(_ item: FallbackDischargePlanMetric)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDischargePlanMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDischargePlanMetricStore: FallbackDischargePlanMetricStore {
        var items: [String: FallbackDischargePlanMetric]
        var order: [String]

        init(items: [String: FallbackDischargePlanMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDischargePlanMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDischargePlanMetric) {
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

        func list() -> [FallbackDischargePlanMetric] {
            var out: [FallbackDischargePlanMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDischargePlanMetricStore() -> any FallbackDischargePlanMetricStore {
        return MemoryFallbackDischargePlanMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDischargePlanMetricStore: FallbackDischargePlanMetricStore {
        var inner: MemoryFallbackDischargePlanMetricStore
        var cache: TTLCache<FallbackDischargePlanMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDischargePlanMetricStore, cache: TTLCache<FallbackDischargePlanMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDischargePlanMetric? {
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

        func save(_ item: FallbackDischargePlanMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDischargePlanMetric] {
            return inner.list()
        }
    }

    static func newCachedFallbackDischargePlanMetricStore(_ inner: MemoryFallbackDischargePlanMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDischargePlanMetricStore {
        return CachedFallbackDischargePlanMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback discharge plan metrics. Empty fields match all.
    final class FallbackDischargePlanMetricQuery {
        var facility: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDischargePlanMetric) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackDischargePlanMetric]) -> [FallbackDischargePlanMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDischargePlanMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDischargePlanMetrics(_ store: any FallbackDischargePlanMetricStore, query: FallbackDischargePlanMetricQuery) -> [FallbackDischargePlanMetric] {
        return query.apply(store.list())
    }
}
