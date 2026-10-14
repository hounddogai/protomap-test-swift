import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy specimen metrics by code.
    protocol LegacySpecimenMetricStore {
        func find(_ code: String) -> LegacySpecimenMetric?
        func save(_ item: LegacySpecimenMetric)
        func remove(_ code: String) -> Bool
        func list() -> [LegacySpecimenMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacySpecimenMetricStore: LegacySpecimenMetricStore {
        var items: [String: LegacySpecimenMetric]
        var order: [String]

        init(items: [String: LegacySpecimenMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacySpecimenMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacySpecimenMetric) {
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

        func list() -> [LegacySpecimenMetric] {
            var out: [LegacySpecimenMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacySpecimenMetricStore() -> any LegacySpecimenMetricStore {
        return MemoryLegacySpecimenMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacySpecimenMetricStore: LegacySpecimenMetricStore {
        var inner: MemoryLegacySpecimenMetricStore
        var cache: TTLCache<LegacySpecimenMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacySpecimenMetricStore, cache: TTLCache<LegacySpecimenMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacySpecimenMetric? {
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

        func save(_ item: LegacySpecimenMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacySpecimenMetric] {
            return inner.list()
        }
    }

    static func newCachedLegacySpecimenMetricStore(_ inner: MemoryLegacySpecimenMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacySpecimenMetricStore {
        return CachedLegacySpecimenMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy specimen metrics. Empty fields match all.
    final class LegacySpecimenMetricQuery {
        var region: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minPriority: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacySpecimenMetric) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacySpecimenMetric]) -> [LegacySpecimenMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacySpecimenMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacySpecimenMetrics(_ store: any LegacySpecimenMetricStore, query: LegacySpecimenMetricQuery) -> [LegacySpecimenMetric] {
        return query.apply(store.list())
    }
}
