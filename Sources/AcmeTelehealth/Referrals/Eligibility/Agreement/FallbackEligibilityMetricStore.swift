import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback eligibility metrics by code.
    protocol FallbackEligibilityMetricStore {
        func find(_ code: String) -> FallbackEligibilityMetric?
        func save(_ item: FallbackEligibilityMetric)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackEligibilityMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackEligibilityMetricStore: FallbackEligibilityMetricStore {
        var items: [String: FallbackEligibilityMetric]
        var order: [String]

        init(items: [String: FallbackEligibilityMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackEligibilityMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackEligibilityMetric) {
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

        func list() -> [FallbackEligibilityMetric] {
            var out: [FallbackEligibilityMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackEligibilityMetricStore() -> any FallbackEligibilityMetricStore {
        return MemoryFallbackEligibilityMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackEligibilityMetricStore: FallbackEligibilityMetricStore {
        var inner: MemoryFallbackEligibilityMetricStore
        var cache: TTLCache<FallbackEligibilityMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackEligibilityMetricStore, cache: TTLCache<FallbackEligibilityMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackEligibilityMetric? {
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

        func save(_ item: FallbackEligibilityMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackEligibilityMetric] {
            return inner.list()
        }
    }

    static func newCachedFallbackEligibilityMetricStore(_ inner: MemoryFallbackEligibilityMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackEligibilityMetricStore {
        return CachedFallbackEligibilityMetricStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback eligibility metrics. Empty fields match all.
    final class FallbackEligibilityMetricQuery {
        var ward: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackEligibilityMetric) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackEligibilityMetric]) -> [FallbackEligibilityMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackEligibilityMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackEligibilityMetrics(_ store: any FallbackEligibilityMetricStore, query: FallbackEligibilityMetricQuery) -> [FallbackEligibilityMetric] {
        return query.apply(store.list())
    }
}
