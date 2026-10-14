import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback closure metrics by code.
    protocol FallbackClosureMetricStore {
        func find(_ code: String) -> FallbackClosureMetric?
        func save(_ item: FallbackClosureMetric)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackClosureMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackClosureMetricStore: FallbackClosureMetricStore {
        var items: [String: FallbackClosureMetric]
        var order: [String]

        init(items: [String: FallbackClosureMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackClosureMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackClosureMetric) {
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

        func list() -> [FallbackClosureMetric] {
            var out: [FallbackClosureMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackClosureMetricStore() -> any FallbackClosureMetricStore {
        return MemoryFallbackClosureMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackClosureMetricStore: FallbackClosureMetricStore {
        var inner: MemoryFallbackClosureMetricStore
        var cache: TTLCache<FallbackClosureMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackClosureMetricStore, cache: TTLCache<FallbackClosureMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackClosureMetric? {
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

        func save(_ item: FallbackClosureMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackClosureMetric] {
            return inner.list()
        }
    }

    static func newCachedFallbackClosureMetricStore(_ inner: MemoryFallbackClosureMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackClosureMetricStore {
        return CachedFallbackClosureMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback closure metrics. Empty fields match all.
    final class FallbackClosureMetricQuery {
        var segment: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackClosureMetric) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
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

        func apply(_ items: [FallbackClosureMetric]) -> [FallbackClosureMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackClosureMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackClosureMetrics(_ store: any FallbackClosureMetricStore, query: FallbackClosureMetricQuery) -> [FallbackClosureMetric] {
        return query.apply(store.list())
    }
}
