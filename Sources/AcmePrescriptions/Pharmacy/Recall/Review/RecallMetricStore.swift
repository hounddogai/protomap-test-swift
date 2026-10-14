import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps recall metrics by code.
    protocol RecallMetricStore {
        func find(_ code: String) -> RecallMetric?
        func save(_ item: RecallMetric)
        func remove(_ code: String) -> Bool
        func list() -> [RecallMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRecallMetricStore: RecallMetricStore {
        var items: [String: RecallMetric]
        var order: [String]

        init(items: [String: RecallMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RecallMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RecallMetric) {
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

        func list() -> [RecallMetric] {
            var out: [RecallMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRecallMetricStore() -> any RecallMetricStore {
        return MemoryRecallMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRecallMetricStore: RecallMetricStore {
        var inner: MemoryRecallMetricStore
        var cache: TTLCache<RecallMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryRecallMetricStore, cache: TTLCache<RecallMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RecallMetric? {
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

        func save(_ item: RecallMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RecallMetric] {
            return inner.list()
        }
    }

    static func newCachedRecallMetricStore(_ inner: MemoryRecallMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RecallMetricStore {
        return CachedRecallMetricStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects recall metrics. Empty fields match all.
    final class RecallMetricQuery {
        var source: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minLimit: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RecallMetric) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
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

        func apply(_ items: [RecallMetric]) -> [RecallMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RecallMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRecallMetrics(_ store: any RecallMetricStore, query: RecallMetricQuery) -> [RecallMetric] {
        return query.apply(store.list())
    }
}
