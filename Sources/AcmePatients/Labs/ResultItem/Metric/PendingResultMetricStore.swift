import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending result metrics by code.
    protocol PendingResultMetricStore {
        func find(_ code: String) -> PendingResultMetric?
        func save(_ item: PendingResultMetric)
        func remove(_ code: String) -> Bool
        func list() -> [PendingResultMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingResultMetricStore: PendingResultMetricStore {
        var items: [String: PendingResultMetric]
        var order: [String]

        init(items: [String: PendingResultMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingResultMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingResultMetric) {
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

        func list() -> [PendingResultMetric] {
            var out: [PendingResultMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingResultMetricStore() -> any PendingResultMetricStore {
        return MemoryPendingResultMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingResultMetricStore: PendingResultMetricStore {
        var inner: MemoryPendingResultMetricStore
        var cache: TTLCache<PendingResultMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingResultMetricStore, cache: TTLCache<PendingResultMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingResultMetric? {
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

        func save(_ item: PendingResultMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingResultMetric] {
            return inner.list()
        }
    }

    static func newCachedPendingResultMetricStore(_ inner: MemoryPendingResultMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingResultMetricStore {
        return CachedPendingResultMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending result metrics. Empty fields match all.
    final class PendingResultMetricQuery {
        var channel: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMargin: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingResultMetric) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingResultMetric]) -> [PendingResultMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingResultMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingResultMetrics(_ store: any PendingResultMetricStore, query: PendingResultMetricQuery) -> [PendingResultMetric] {
        return query.apply(store.list())
    }
}
