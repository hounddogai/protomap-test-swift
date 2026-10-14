import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps fallback census metrics by code.
    protocol FallbackCensusMetricStore {
        func find(_ code: String) -> FallbackCensusMetric?
        func save(_ item: FallbackCensusMetric)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCensusMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCensusMetricStore: FallbackCensusMetricStore {
        var items: [String: FallbackCensusMetric]
        var order: [String]

        init(items: [String: FallbackCensusMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCensusMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCensusMetric) {
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

        func list() -> [FallbackCensusMetric] {
            var out: [FallbackCensusMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCensusMetricStore() -> any FallbackCensusMetricStore {
        return MemoryFallbackCensusMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCensusMetricStore: FallbackCensusMetricStore {
        var inner: MemoryFallbackCensusMetricStore
        var cache: TTLCache<FallbackCensusMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCensusMetricStore, cache: TTLCache<FallbackCensusMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCensusMetric? {
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

        func save(_ item: FallbackCensusMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCensusMetric] {
            return inner.list()
        }
    }

    static func newCachedFallbackCensusMetricStore(_ inner: MemoryFallbackCensusMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCensusMetricStore {
        return CachedFallbackCensusMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback census metrics. Empty fields match all.
    final class FallbackCensusMetricQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCensusMetric) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCensusMetric]) -> [FallbackCensusMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCensusMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCensusMetrics(_ store: any FallbackCensusMetricStore, query: FallbackCensusMetricQuery) -> [FallbackCensusMetric] {
        return query.apply(store.list())
    }
}
