import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps pending worklist metrics by code.
    protocol PendingWorklistMetricStore {
        func find(_ code: String) -> PendingWorklistMetric?
        func save(_ item: PendingWorklistMetric)
        func remove(_ code: String) -> Bool
        func list() -> [PendingWorklistMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingWorklistMetricStore: PendingWorklistMetricStore {
        var items: [String: PendingWorklistMetric]
        var order: [String]

        init(items: [String: PendingWorklistMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingWorklistMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingWorklistMetric) {
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

        func list() -> [PendingWorklistMetric] {
            var out: [PendingWorklistMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingWorklistMetricStore() -> any PendingWorklistMetricStore {
        return MemoryPendingWorklistMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingWorklistMetricStore: PendingWorklistMetricStore {
        var inner: MemoryPendingWorklistMetricStore
        var cache: TTLCache<PendingWorklistMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingWorklistMetricStore, cache: TTLCache<PendingWorklistMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingWorklistMetric? {
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

        func save(_ item: PendingWorklistMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingWorklistMetric] {
            return inner.list()
        }
    }

    static func newCachedPendingWorklistMetricStore(_ inner: MemoryPendingWorklistMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingWorklistMetricStore {
        return CachedPendingWorklistMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending worklist metrics. Empty fields match all.
    final class PendingWorklistMetricQuery {
        var label: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minLimit: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingWorklistMetric) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PendingWorklistMetric]) -> [PendingWorklistMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingWorklistMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingWorklistMetrics(_ store: any PendingWorklistMetricStore, query: PendingWorklistMetricQuery) -> [PendingWorklistMetric] {
        return query.apply(store.list())
    }
}
