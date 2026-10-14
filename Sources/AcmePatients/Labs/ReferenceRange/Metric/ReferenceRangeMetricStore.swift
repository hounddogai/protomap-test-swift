import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range metrics by code.
    protocol ReferenceRangeMetricStore {
        func find(_ code: String) -> ReferenceRangeMetric?
        func save(_ item: ReferenceRangeMetric)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeMetricStore: ReferenceRangeMetricStore {
        var items: [String: ReferenceRangeMetric]
        var order: [String]

        init(items: [String: ReferenceRangeMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeMetric) {
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

        func list() -> [ReferenceRangeMetric] {
            var out: [ReferenceRangeMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeMetricStore() -> any ReferenceRangeMetricStore {
        return MemoryReferenceRangeMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeMetricStore: ReferenceRangeMetricStore {
        var inner: MemoryReferenceRangeMetricStore
        var cache: TTLCache<ReferenceRangeMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeMetricStore, cache: TTLCache<ReferenceRangeMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeMetric? {
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

        func save(_ item: ReferenceRangeMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeMetric] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeMetricStore(_ inner: MemoryReferenceRangeMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeMetricStore {
        return CachedReferenceRangeMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range metrics. Empty fields match all.
    final class ReferenceRangeMetricQuery {
        var unit: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeMetric) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeMetric]) -> [ReferenceRangeMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeMetrics(_ store: any ReferenceRangeMetricStore, query: ReferenceRangeMetricQuery) -> [ReferenceRangeMetric] {
        return query.apply(store.list())
    }
}
