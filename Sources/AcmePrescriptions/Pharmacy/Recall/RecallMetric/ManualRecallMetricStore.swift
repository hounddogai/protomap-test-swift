import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps manual recall metrics by code.
    protocol ManualRecallMetricStore {
        func find(_ code: String) -> ManualRecallMetric?
        func save(_ item: ManualRecallMetric)
        func remove(_ code: String) -> Bool
        func list() -> [ManualRecallMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualRecallMetricStore: ManualRecallMetricStore {
        var items: [String: ManualRecallMetric]
        var order: [String]

        init(items: [String: ManualRecallMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualRecallMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualRecallMetric) {
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

        func list() -> [ManualRecallMetric] {
            var out: [ManualRecallMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualRecallMetricStore() -> any ManualRecallMetricStore {
        return MemoryManualRecallMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualRecallMetricStore: ManualRecallMetricStore {
        var inner: MemoryManualRecallMetricStore
        var cache: TTLCache<ManualRecallMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualRecallMetricStore, cache: TTLCache<ManualRecallMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualRecallMetric? {
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

        func save(_ item: ManualRecallMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualRecallMetric] {
            return inner.list()
        }
    }

    static func newCachedManualRecallMetricStore(_ inner: MemoryManualRecallMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualRecallMetricStore {
        return CachedManualRecallMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual recall metrics. Empty fields match all.
    final class ManualRecallMetricQuery {
        var label: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualRecallMetric) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualRecallMetric]) -> [ManualRecallMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualRecallMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualRecallMetrics(_ store: any ManualRecallMetricStore, query: ManualRecallMetricQuery) -> [ManualRecallMetric] {
        return query.apply(store.list())
    }
}
