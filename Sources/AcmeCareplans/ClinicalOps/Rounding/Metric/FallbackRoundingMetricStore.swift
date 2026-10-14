import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps fallback rounding metrics by code.
    protocol FallbackRoundingMetricStore {
        func find(_ code: String) -> FallbackRoundingMetric?
        func save(_ item: FallbackRoundingMetric)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackRoundingMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackRoundingMetricStore: FallbackRoundingMetricStore {
        var items: [String: FallbackRoundingMetric]
        var order: [String]

        init(items: [String: FallbackRoundingMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackRoundingMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackRoundingMetric) {
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

        func list() -> [FallbackRoundingMetric] {
            var out: [FallbackRoundingMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackRoundingMetricStore() -> any FallbackRoundingMetricStore {
        return MemoryFallbackRoundingMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackRoundingMetricStore: FallbackRoundingMetricStore {
        var inner: MemoryFallbackRoundingMetricStore
        var cache: TTLCache<FallbackRoundingMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackRoundingMetricStore, cache: TTLCache<FallbackRoundingMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackRoundingMetric? {
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

        func save(_ item: FallbackRoundingMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackRoundingMetric] {
            return inner.list()
        }
    }

    static func newCachedFallbackRoundingMetricStore(_ inner: MemoryFallbackRoundingMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackRoundingMetricStore {
        return CachedFallbackRoundingMetricStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback rounding metrics. Empty fields match all.
    final class FallbackRoundingMetricQuery {
        var name: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackRoundingMetric) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackRoundingMetric]) -> [FallbackRoundingMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackRoundingMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackRoundingMetrics(_ store: any FallbackRoundingMetricStore, query: FallbackRoundingMetricQuery) -> [FallbackRoundingMetric] {
        return query.apply(store.list())
    }
}
