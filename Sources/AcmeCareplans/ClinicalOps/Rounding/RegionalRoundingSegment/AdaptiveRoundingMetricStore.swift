import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps adaptive rounding metrics by code.
    protocol AdaptiveRoundingMetricStore {
        func find(_ code: String) -> AdaptiveRoundingMetric?
        func save(_ item: AdaptiveRoundingMetric)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveRoundingMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveRoundingMetricStore: AdaptiveRoundingMetricStore {
        var items: [String: AdaptiveRoundingMetric]
        var order: [String]

        init(items: [String: AdaptiveRoundingMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveRoundingMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveRoundingMetric) {
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

        func list() -> [AdaptiveRoundingMetric] {
            var out: [AdaptiveRoundingMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveRoundingMetricStore() -> any AdaptiveRoundingMetricStore {
        return MemoryAdaptiveRoundingMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveRoundingMetricStore: AdaptiveRoundingMetricStore {
        var inner: MemoryAdaptiveRoundingMetricStore
        var cache: TTLCache<AdaptiveRoundingMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveRoundingMetricStore, cache: TTLCache<AdaptiveRoundingMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveRoundingMetric? {
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

        func save(_ item: AdaptiveRoundingMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveRoundingMetric] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveRoundingMetricStore(_ inner: MemoryAdaptiveRoundingMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveRoundingMetricStore {
        return CachedAdaptiveRoundingMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive rounding metrics. Empty fields match all.
    final class AdaptiveRoundingMetricQuery {
        var region: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRetries: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveRoundingMetric) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveRoundingMetric]) -> [AdaptiveRoundingMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveRoundingMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveRoundingMetrics(_ store: any AdaptiveRoundingMetricStore, query: AdaptiveRoundingMetricQuery) -> [AdaptiveRoundingMetric] {
        return query.apply(store.list())
    }
}
