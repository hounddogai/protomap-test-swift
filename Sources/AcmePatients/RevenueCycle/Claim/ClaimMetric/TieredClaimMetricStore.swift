import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered claim metrics by code.
    protocol TieredClaimMetricStore {
        func find(_ code: String) -> TieredClaimMetric?
        func save(_ item: TieredClaimMetric)
        func remove(_ code: String) -> Bool
        func list() -> [TieredClaimMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredClaimMetricStore: TieredClaimMetricStore {
        var items: [String: TieredClaimMetric]
        var order: [String]

        init(items: [String: TieredClaimMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredClaimMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredClaimMetric) {
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

        func list() -> [TieredClaimMetric] {
            var out: [TieredClaimMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredClaimMetricStore() -> any TieredClaimMetricStore {
        return MemoryTieredClaimMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredClaimMetricStore: TieredClaimMetricStore {
        var inner: MemoryTieredClaimMetricStore
        var cache: TTLCache<TieredClaimMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredClaimMetricStore, cache: TTLCache<TieredClaimMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredClaimMetric? {
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

        func save(_ item: TieredClaimMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredClaimMetric] {
            return inner.list()
        }
    }

    static func newCachedTieredClaimMetricStore(_ inner: MemoryTieredClaimMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredClaimMetricStore {
        return CachedTieredClaimMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered claim metrics. Empty fields match all.
    final class TieredClaimMetricQuery {
        var region: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredClaimMetric) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredClaimMetric]) -> [TieredClaimMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredClaimMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredClaimMetrics(_ store: any TieredClaimMetricStore, query: TieredClaimMetricQuery) -> [TieredClaimMetric] {
        return query.apply(store.list())
    }
}
