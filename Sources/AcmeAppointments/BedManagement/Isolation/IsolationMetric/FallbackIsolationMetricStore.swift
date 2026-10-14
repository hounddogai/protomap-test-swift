import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps fallback isolation metrics by code.
    protocol FallbackIsolationMetricStore {
        func find(_ code: String) -> FallbackIsolationMetric?
        func save(_ item: FallbackIsolationMetric)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackIsolationMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackIsolationMetricStore: FallbackIsolationMetricStore {
        var items: [String: FallbackIsolationMetric]
        var order: [String]

        init(items: [String: FallbackIsolationMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackIsolationMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackIsolationMetric) {
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

        func list() -> [FallbackIsolationMetric] {
            var out: [FallbackIsolationMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackIsolationMetricStore() -> any FallbackIsolationMetricStore {
        return MemoryFallbackIsolationMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackIsolationMetricStore: FallbackIsolationMetricStore {
        var inner: MemoryFallbackIsolationMetricStore
        var cache: TTLCache<FallbackIsolationMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackIsolationMetricStore, cache: TTLCache<FallbackIsolationMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackIsolationMetric? {
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

        func save(_ item: FallbackIsolationMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackIsolationMetric] {
            return inner.list()
        }
    }

    static func newCachedFallbackIsolationMetricStore(_ inner: MemoryFallbackIsolationMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackIsolationMetricStore {
        return CachedFallbackIsolationMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback isolation metrics. Empty fields match all.
    final class FallbackIsolationMetricQuery {
        var title: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minAmount: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackIsolationMetric) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackIsolationMetric]) -> [FallbackIsolationMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackIsolationMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackIsolationMetrics(_ store: any FallbackIsolationMetricStore, query: FallbackIsolationMetricQuery) -> [FallbackIsolationMetric] {
        return query.apply(store.list())
    }
}
