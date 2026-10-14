import AcmePlatform
import Foundation

extension Labs {
    /// Keeps primary specimen metrics by code.
    protocol PrimarySpecimenMetricStore {
        func find(_ code: String) -> PrimarySpecimenMetric?
        func save(_ item: PrimarySpecimenMetric)
        func remove(_ code: String) -> Bool
        func list() -> [PrimarySpecimenMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimarySpecimenMetricStore: PrimarySpecimenMetricStore {
        var items: [String: PrimarySpecimenMetric]
        var order: [String]

        init(items: [String: PrimarySpecimenMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimarySpecimenMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimarySpecimenMetric) {
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

        func list() -> [PrimarySpecimenMetric] {
            var out: [PrimarySpecimenMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimarySpecimenMetricStore() -> any PrimarySpecimenMetricStore {
        return MemoryPrimarySpecimenMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimarySpecimenMetricStore: PrimarySpecimenMetricStore {
        var inner: MemoryPrimarySpecimenMetricStore
        var cache: TTLCache<PrimarySpecimenMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimarySpecimenMetricStore, cache: TTLCache<PrimarySpecimenMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimarySpecimenMetric? {
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

        func save(_ item: PrimarySpecimenMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimarySpecimenMetric] {
            return inner.list()
        }
    }

    static func newCachedPrimarySpecimenMetricStore(_ inner: MemoryPrimarySpecimenMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimarySpecimenMetricStore {
        return CachedPrimarySpecimenMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary specimen metrics. Empty fields match all.
    final class PrimarySpecimenMetricQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimarySpecimenMetric) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimarySpecimenMetric]) -> [PrimarySpecimenMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimarySpecimenMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimarySpecimenMetrics(_ store: any PrimarySpecimenMetricStore, query: PrimarySpecimenMetricQuery) -> [PrimarySpecimenMetric] {
        return query.apply(store.list())
    }
}
