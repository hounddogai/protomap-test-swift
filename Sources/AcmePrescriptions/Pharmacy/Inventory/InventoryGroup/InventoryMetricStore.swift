import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory metrics by code.
    protocol InventoryMetricStore {
        func find(_ code: String) -> InventoryMetric?
        func save(_ item: InventoryMetric)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryMetricStore: InventoryMetricStore {
        var items: [String: InventoryMetric]
        var order: [String]

        init(items: [String: InventoryMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryMetric) {
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

        func list() -> [InventoryMetric] {
            var out: [InventoryMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryMetricStore() -> any InventoryMetricStore {
        return MemoryInventoryMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryMetricStore: InventoryMetricStore {
        var inner: MemoryInventoryMetricStore
        var cache: TTLCache<InventoryMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryMetricStore, cache: TTLCache<InventoryMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryMetric? {
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

        func save(_ item: InventoryMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryMetric] {
            return inner.list()
        }
    }

    static func newCachedInventoryMetricStore(_ inner: MemoryInventoryMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryMetricStore {
        return CachedInventoryMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory metrics. Empty fields match all.
    final class InventoryMetricQuery {
        var source: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minRatio: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryMetric) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryMetric]) -> [InventoryMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryMetrics(_ store: any InventoryMetricStore, query: InventoryMetricQuery) -> [InventoryMetric] {
        return query.apply(store.list())
    }
}
