import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps adaptive cleaning metrics by code.
    protocol AdaptiveCleaningMetricStore {
        func find(_ code: String) -> AdaptiveCleaningMetric?
        func save(_ item: AdaptiveCleaningMetric)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveCleaningMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveCleaningMetricStore: AdaptiveCleaningMetricStore {
        var items: [String: AdaptiveCleaningMetric]
        var order: [String]

        init(items: [String: AdaptiveCleaningMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveCleaningMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveCleaningMetric) {
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

        func list() -> [AdaptiveCleaningMetric] {
            var out: [AdaptiveCleaningMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveCleaningMetricStore() -> any AdaptiveCleaningMetricStore {
        return MemoryAdaptiveCleaningMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveCleaningMetricStore: AdaptiveCleaningMetricStore {
        var inner: MemoryAdaptiveCleaningMetricStore
        var cache: TTLCache<AdaptiveCleaningMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveCleaningMetricStore, cache: TTLCache<AdaptiveCleaningMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveCleaningMetric? {
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

        func save(_ item: AdaptiveCleaningMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveCleaningMetric] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveCleaningMetricStore(_ inner: MemoryAdaptiveCleaningMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveCleaningMetricStore {
        return CachedAdaptiveCleaningMetricStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive cleaning metrics. Empty fields match all.
    final class AdaptiveCleaningMetricQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveCleaningMetric) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [AdaptiveCleaningMetric]) -> [AdaptiveCleaningMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveCleaningMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveCleaningMetrics(_ store: any AdaptiveCleaningMetricStore, query: AdaptiveCleaningMetricQuery) -> [AdaptiveCleaningMetric] {
        return query.apply(store.list())
    }
}
