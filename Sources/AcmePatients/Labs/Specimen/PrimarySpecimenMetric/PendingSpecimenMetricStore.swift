import AcmePlatform
import Foundation

extension Labs {
    /// Keeps pending specimen metrics by code.
    protocol PendingSpecimenMetricStore {
        func find(_ code: String) -> PendingSpecimenMetric?
        func save(_ item: PendingSpecimenMetric)
        func remove(_ code: String) -> Bool
        func list() -> [PendingSpecimenMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingSpecimenMetricStore: PendingSpecimenMetricStore {
        var items: [String: PendingSpecimenMetric]
        var order: [String]

        init(items: [String: PendingSpecimenMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingSpecimenMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingSpecimenMetric) {
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

        func list() -> [PendingSpecimenMetric] {
            var out: [PendingSpecimenMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingSpecimenMetricStore() -> any PendingSpecimenMetricStore {
        return MemoryPendingSpecimenMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingSpecimenMetricStore: PendingSpecimenMetricStore {
        var inner: MemoryPendingSpecimenMetricStore
        var cache: TTLCache<PendingSpecimenMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingSpecimenMetricStore, cache: TTLCache<PendingSpecimenMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingSpecimenMetric? {
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

        func save(_ item: PendingSpecimenMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingSpecimenMetric] {
            return inner.list()
        }
    }

    static func newCachedPendingSpecimenMetricStore(_ inner: MemoryPendingSpecimenMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingSpecimenMetricStore {
        return CachedPendingSpecimenMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending specimen metrics. Empty fields match all.
    final class PendingSpecimenMetricQuery {
        var label: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minCopay: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingSpecimenMetric) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [PendingSpecimenMetric]) -> [PendingSpecimenMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingSpecimenMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingSpecimenMetrics(_ store: any PendingSpecimenMetricStore, query: PendingSpecimenMetricQuery) -> [PendingSpecimenMetric] {
        return query.apply(store.list())
    }
}
