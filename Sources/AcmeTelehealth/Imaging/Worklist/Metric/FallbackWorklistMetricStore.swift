import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps fallback worklist metrics by code.
    protocol FallbackWorklistMetricStore {
        func find(_ code: String) -> FallbackWorklistMetric?
        func save(_ item: FallbackWorklistMetric)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackWorklistMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackWorklistMetricStore: FallbackWorklistMetricStore {
        var items: [String: FallbackWorklistMetric]
        var order: [String]

        init(items: [String: FallbackWorklistMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackWorklistMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackWorklistMetric) {
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

        func list() -> [FallbackWorklistMetric] {
            var out: [FallbackWorklistMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackWorklistMetricStore() -> any FallbackWorklistMetricStore {
        return MemoryFallbackWorklistMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackWorklistMetricStore: FallbackWorklistMetricStore {
        var inner: MemoryFallbackWorklistMetricStore
        var cache: TTLCache<FallbackWorklistMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackWorklistMetricStore, cache: TTLCache<FallbackWorklistMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackWorklistMetric? {
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

        func save(_ item: FallbackWorklistMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackWorklistMetric] {
            return inner.list()
        }
    }

    static func newCachedFallbackWorklistMetricStore(_ inner: MemoryFallbackWorklistMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackWorklistMetricStore {
        return CachedFallbackWorklistMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback worklist metrics. Empty fields match all.
    final class FallbackWorklistMetricQuery {
        var source: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minCost: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackWorklistMetric) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackWorklistMetric]) -> [FallbackWorklistMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackWorklistMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackWorklistMetrics(_ store: any FallbackWorklistMetricStore, query: FallbackWorklistMetricQuery) -> [FallbackWorklistMetric] {
        return query.apply(store.list())
    }
}
