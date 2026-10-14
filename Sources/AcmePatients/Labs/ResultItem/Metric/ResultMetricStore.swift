import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result metrics by code.
    protocol ResultMetricStore {
        func find(_ code: String) -> ResultMetric?
        func save(_ item: ResultMetric)
        func remove(_ code: String) -> Bool
        func list() -> [ResultMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultMetricStore: ResultMetricStore {
        var items: [String: ResultMetric]
        var order: [String]

        init(items: [String: ResultMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultMetric) {
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

        func list() -> [ResultMetric] {
            var out: [ResultMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultMetricStore() -> any ResultMetricStore {
        return MemoryResultMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultMetricStore: ResultMetricStore {
        var inner: MemoryResultMetricStore
        var cache: TTLCache<ResultMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultMetricStore, cache: TTLCache<ResultMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultMetric? {
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

        func save(_ item: ResultMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultMetric] {
            return inner.list()
        }
    }

    static func newCachedResultMetricStore(_ inner: MemoryResultMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultMetricStore {
        return CachedResultMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result metrics. Empty fields match all.
    final class ResultMetricQuery {
        var name: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minLimit: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultMetric) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultMetric]) -> [ResultMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultMetrics(_ store: any ResultMetricStore, query: ResultMetricQuery) -> [ResultMetric] {
        return query.apply(store.list())
    }
}
