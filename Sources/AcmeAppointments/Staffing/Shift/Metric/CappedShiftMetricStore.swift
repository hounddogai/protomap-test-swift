import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps capped shift metrics by code.
    protocol CappedShiftMetricStore {
        func find(_ code: String) -> CappedShiftMetric?
        func save(_ item: CappedShiftMetric)
        func remove(_ code: String) -> Bool
        func list() -> [CappedShiftMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedShiftMetricStore: CappedShiftMetricStore {
        var items: [String: CappedShiftMetric]
        var order: [String]

        init(items: [String: CappedShiftMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedShiftMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedShiftMetric) {
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

        func list() -> [CappedShiftMetric] {
            var out: [CappedShiftMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedShiftMetricStore() -> any CappedShiftMetricStore {
        return MemoryCappedShiftMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedShiftMetricStore: CappedShiftMetricStore {
        var inner: MemoryCappedShiftMetricStore
        var cache: TTLCache<CappedShiftMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedShiftMetricStore, cache: TTLCache<CappedShiftMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedShiftMetric? {
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

        func save(_ item: CappedShiftMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedShiftMetric] {
            return inner.list()
        }
    }

    static func newCachedCappedShiftMetricStore(_ inner: MemoryCappedShiftMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedShiftMetricStore {
        return CachedCappedShiftMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped shift metrics. Empty fields match all.
    final class CappedShiftMetricQuery {
        var channel: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minSequence: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedShiftMetric) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedShiftMetric]) -> [CappedShiftMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedShiftMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedShiftMetrics(_ store: any CappedShiftMetricStore, query: CappedShiftMetricQuery) -> [CappedShiftMetric] {
        return query.apply(store.list())
    }
}
