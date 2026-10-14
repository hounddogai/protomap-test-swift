import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps census metrics by code.
    protocol CensusMetricStore {
        func find(_ code: String) -> CensusMetric?
        func save(_ item: CensusMetric)
        func remove(_ code: String) -> Bool
        func list() -> [CensusMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCensusMetricStore: CensusMetricStore {
        var items: [String: CensusMetric]
        var order: [String]

        init(items: [String: CensusMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CensusMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CensusMetric) {
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

        func list() -> [CensusMetric] {
            var out: [CensusMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCensusMetricStore() -> any CensusMetricStore {
        return MemoryCensusMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCensusMetricStore: CensusMetricStore {
        var inner: MemoryCensusMetricStore
        var cache: TTLCache<CensusMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryCensusMetricStore, cache: TTLCache<CensusMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CensusMetric? {
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

        func save(_ item: CensusMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CensusMetric] {
            return inner.list()
        }
    }

    static func newCachedCensusMetricStore(_ inner: MemoryCensusMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CensusMetricStore {
        return CachedCensusMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects census metrics. Empty fields match all.
    final class CensusMetricQuery {
        var facility: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minSequence: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CensusMetric) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CensusMetric]) -> [CensusMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CensusMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCensusMetrics(_ store: any CensusMetricStore, query: CensusMetricQuery) -> [CensusMetric] {
        return query.apply(store.list())
    }
}
