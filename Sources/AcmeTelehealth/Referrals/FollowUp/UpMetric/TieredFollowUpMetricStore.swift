import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered follow up metrics by code.
    protocol TieredFollowUpMetricStore {
        func find(_ code: String) -> TieredFollowUpMetric?
        func save(_ item: TieredFollowUpMetric)
        func remove(_ code: String) -> Bool
        func list() -> [TieredFollowUpMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredFollowUpMetricStore: TieredFollowUpMetricStore {
        var items: [String: TieredFollowUpMetric]
        var order: [String]

        init(items: [String: TieredFollowUpMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredFollowUpMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredFollowUpMetric) {
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

        func list() -> [TieredFollowUpMetric] {
            var out: [TieredFollowUpMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredFollowUpMetricStore() -> any TieredFollowUpMetricStore {
        return MemoryTieredFollowUpMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredFollowUpMetricStore: TieredFollowUpMetricStore {
        var inner: MemoryTieredFollowUpMetricStore
        var cache: TTLCache<TieredFollowUpMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredFollowUpMetricStore, cache: TTLCache<TieredFollowUpMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredFollowUpMetric? {
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

        func save(_ item: TieredFollowUpMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredFollowUpMetric] {
            return inner.list()
        }
    }

    static func newCachedTieredFollowUpMetricStore(_ inner: MemoryTieredFollowUpMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredFollowUpMetricStore {
        return CachedTieredFollowUpMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered follow up metrics. Empty fields match all.
    final class TieredFollowUpMetricQuery {
        var unit: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredFollowUpMetric) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredFollowUpMetric]) -> [TieredFollowUpMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredFollowUpMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredFollowUpMetrics(_ store: any TieredFollowUpMetricStore, query: TieredFollowUpMetricQuery) -> [TieredFollowUpMetric] {
        return query.apply(store.list())
    }
}
