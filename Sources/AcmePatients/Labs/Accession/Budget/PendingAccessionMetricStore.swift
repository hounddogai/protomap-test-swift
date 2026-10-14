import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending accession metrics by code.
    protocol PendingAccessionMetricStore {
        func find(_ code: String) -> PendingAccessionMetric?
        func save(_ item: PendingAccessionMetric)
        func remove(_ code: String) -> Bool
        func list() -> [PendingAccessionMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingAccessionMetricStore: PendingAccessionMetricStore {
        var items: [String: PendingAccessionMetric]
        var order: [String]

        init(items: [String: PendingAccessionMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingAccessionMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingAccessionMetric) {
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

        func list() -> [PendingAccessionMetric] {
            var out: [PendingAccessionMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingAccessionMetricStore() -> any PendingAccessionMetricStore {
        return MemoryPendingAccessionMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingAccessionMetricStore: PendingAccessionMetricStore {
        var inner: MemoryPendingAccessionMetricStore
        var cache: TTLCache<PendingAccessionMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingAccessionMetricStore, cache: TTLCache<PendingAccessionMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingAccessionMetric? {
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

        func save(_ item: PendingAccessionMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingAccessionMetric] {
            return inner.list()
        }
    }

    static func newCachedPendingAccessionMetricStore(_ inner: MemoryPendingAccessionMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingAccessionMetricStore {
        return CachedPendingAccessionMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending accession metrics. Empty fields match all.
    final class PendingAccessionMetricQuery {
        var label: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVersion: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingAccessionMetric) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingAccessionMetric]) -> [PendingAccessionMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingAccessionMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingAccessionMetrics(_ store: any PendingAccessionMetricStore, query: PendingAccessionMetricQuery) -> [PendingAccessionMetric] {
        return query.apply(store.list())
    }
}
