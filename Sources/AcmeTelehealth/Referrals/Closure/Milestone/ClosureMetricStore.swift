import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps closure metrics by code.
    protocol ClosureMetricStore {
        func find(_ code: String) -> ClosureMetric?
        func save(_ item: ClosureMetric)
        func remove(_ code: String) -> Bool
        func list() -> [ClosureMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClosureMetricStore: ClosureMetricStore {
        var items: [String: ClosureMetric]
        var order: [String]

        init(items: [String: ClosureMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClosureMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClosureMetric) {
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

        func list() -> [ClosureMetric] {
            var out: [ClosureMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClosureMetricStore() -> any ClosureMetricStore {
        return MemoryClosureMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClosureMetricStore: ClosureMetricStore {
        var inner: MemoryClosureMetricStore
        var cache: TTLCache<ClosureMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryClosureMetricStore, cache: TTLCache<ClosureMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClosureMetric? {
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

        func save(_ item: ClosureMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClosureMetric] {
            return inner.list()
        }
    }

    static func newCachedClosureMetricStore(_ inner: MemoryClosureMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClosureMetricStore {
        return CachedClosureMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects closure metrics. Empty fields match all.
    final class ClosureMetricQuery {
        var source: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRetries: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClosureMetric) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [ClosureMetric]) -> [ClosureMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClosureMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClosureMetrics(_ store: any ClosureMetricStore, query: ClosureMetricQuery) -> [ClosureMetric] {
        return query.apply(store.list())
    }
}
