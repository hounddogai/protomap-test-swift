import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen metrics by code.
    protocol SpecimenMetricStore {
        func find(_ code: String) -> SpecimenMetric?
        func save(_ item: SpecimenMetric)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenMetricStore: SpecimenMetricStore {
        var items: [String: SpecimenMetric]
        var order: [String]

        init(items: [String: SpecimenMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenMetric) {
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

        func list() -> [SpecimenMetric] {
            var out: [SpecimenMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenMetricStore() -> any SpecimenMetricStore {
        return MemorySpecimenMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenMetricStore: SpecimenMetricStore {
        var inner: MemorySpecimenMetricStore
        var cache: TTLCache<SpecimenMetric>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenMetricStore, cache: TTLCache<SpecimenMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenMetric? {
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

        func save(_ item: SpecimenMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenMetric] {
            return inner.list()
        }
    }

    static func newCachedSpecimenMetricStore(_ inner: MemorySpecimenMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenMetricStore {
        return CachedSpecimenMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen metrics. Empty fields match all.
    final class SpecimenMetricQuery {
        var title: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minCost: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenMetric) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SpecimenMetric]) -> [SpecimenMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenMetrics(_ store: any SpecimenMetricStore, query: SpecimenMetricQuery) -> [SpecimenMetric] {
        return query.apply(store.list())
    }
}
