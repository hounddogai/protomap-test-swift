import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps strict worklist metrics by code.
    protocol StrictWorklistMetricStore {
        func find(_ code: String) -> StrictWorklistMetric?
        func save(_ item: StrictWorklistMetric)
        func remove(_ code: String) -> Bool
        func list() -> [StrictWorklistMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictWorklistMetricStore: StrictWorklistMetricStore {
        var items: [String: StrictWorklistMetric]
        var order: [String]

        init(items: [String: StrictWorklistMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictWorklistMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictWorklistMetric) {
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

        func list() -> [StrictWorklistMetric] {
            var out: [StrictWorklistMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictWorklistMetricStore() -> any StrictWorklistMetricStore {
        return MemoryStrictWorklistMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictWorklistMetricStore: StrictWorklistMetricStore {
        var inner: MemoryStrictWorklistMetricStore
        var cache: TTLCache<StrictWorklistMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictWorklistMetricStore, cache: TTLCache<StrictWorklistMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictWorklistMetric? {
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

        func save(_ item: StrictWorklistMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictWorklistMetric] {
            return inner.list()
        }
    }

    static func newCachedStrictWorklistMetricStore(_ inner: MemoryStrictWorklistMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictWorklistMetricStore {
        return CachedStrictWorklistMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict worklist metrics. Empty fields match all.
    final class StrictWorklistMetricQuery {
        var title: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictWorklistMetric) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictWorklistMetric]) -> [StrictWorklistMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictWorklistMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictWorklistMetrics(_ store: any StrictWorklistMetricStore, query: StrictWorklistMetricQuery) -> [StrictWorklistMetric] {
        return query.apply(store.list())
    }
}
