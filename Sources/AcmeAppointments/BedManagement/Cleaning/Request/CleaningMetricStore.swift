import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning metrics by code.
    protocol CleaningMetricStore {
        func find(_ code: String) -> CleaningMetric?
        func save(_ item: CleaningMetric)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningMetricStore: CleaningMetricStore {
        var items: [String: CleaningMetric]
        var order: [String]

        init(items: [String: CleaningMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningMetric) {
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

        func list() -> [CleaningMetric] {
            var out: [CleaningMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningMetricStore() -> any CleaningMetricStore {
        return MemoryCleaningMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningMetricStore: CleaningMetricStore {
        var inner: MemoryCleaningMetricStore
        var cache: TTLCache<CleaningMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningMetricStore, cache: TTLCache<CleaningMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningMetric? {
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

        func save(_ item: CleaningMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningMetric] {
            return inner.list()
        }
    }

    static func newCachedCleaningMetricStore(_ inner: MemoryCleaningMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningMetricStore {
        return CachedCleaningMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning metrics. Empty fields match all.
    final class CleaningMetricQuery {
        var country: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minWeight: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningMetric) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningMetric]) -> [CleaningMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningMetrics(_ store: any CleaningMetricStore, query: CleaningMetricQuery) -> [CleaningMetric] {
        return query.apply(store.list())
    }
}
