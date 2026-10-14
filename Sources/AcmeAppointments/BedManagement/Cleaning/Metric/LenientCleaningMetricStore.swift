import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient cleaning metrics by code.
    protocol LenientCleaningMetricStore {
        func find(_ code: String) -> LenientCleaningMetric?
        func save(_ item: LenientCleaningMetric)
        func remove(_ code: String) -> Bool
        func list() -> [LenientCleaningMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientCleaningMetricStore: LenientCleaningMetricStore {
        var items: [String: LenientCleaningMetric]
        var order: [String]

        init(items: [String: LenientCleaningMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientCleaningMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientCleaningMetric) {
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

        func list() -> [LenientCleaningMetric] {
            var out: [LenientCleaningMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientCleaningMetricStore() -> any LenientCleaningMetricStore {
        return MemoryLenientCleaningMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientCleaningMetricStore: LenientCleaningMetricStore {
        var inner: MemoryLenientCleaningMetricStore
        var cache: TTLCache<LenientCleaningMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientCleaningMetricStore, cache: TTLCache<LenientCleaningMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientCleaningMetric? {
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

        func save(_ item: LenientCleaningMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientCleaningMetric] {
            return inner.list()
        }
    }

    static func newCachedLenientCleaningMetricStore(_ inner: MemoryLenientCleaningMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientCleaningMetricStore {
        return CachedLenientCleaningMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient cleaning metrics. Empty fields match all.
    final class LenientCleaningMetricQuery {
        var region: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientCleaningMetric) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientCleaningMetric]) -> [LenientCleaningMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientCleaningMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientCleaningMetrics(_ store: any LenientCleaningMetricStore, query: LenientCleaningMetricQuery) -> [LenientCleaningMetric] {
        return query.apply(store.list())
    }
}
