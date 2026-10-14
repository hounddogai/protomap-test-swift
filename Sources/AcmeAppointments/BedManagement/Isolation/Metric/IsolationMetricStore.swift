import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation metrics by code.
    protocol IsolationMetricStore {
        func find(_ code: String) -> IsolationMetric?
        func save(_ item: IsolationMetric)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationMetricStore: IsolationMetricStore {
        var items: [String: IsolationMetric]
        var order: [String]

        init(items: [String: IsolationMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationMetric) {
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

        func list() -> [IsolationMetric] {
            var out: [IsolationMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationMetricStore() -> any IsolationMetricStore {
        return MemoryIsolationMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationMetricStore: IsolationMetricStore {
        var inner: MemoryIsolationMetricStore
        var cache: TTLCache<IsolationMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationMetricStore, cache: TTLCache<IsolationMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationMetric? {
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

        func save(_ item: IsolationMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationMetric] {
            return inner.list()
        }
    }

    static func newCachedIsolationMetricStore(_ inner: MemoryIsolationMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationMetricStore {
        return CachedIsolationMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation metrics. Empty fields match all.
    final class IsolationMetricQuery {
        var name: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCopay: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationMetric) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationMetric]) -> [IsolationMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationMetrics(_ store: any IsolationMetricStore, query: IsolationMetricQuery) -> [IsolationMetric] {
        return query.apply(store.list())
    }
}
