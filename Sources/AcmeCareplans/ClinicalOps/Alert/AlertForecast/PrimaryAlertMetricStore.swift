import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps primary alert metrics by code.
    protocol PrimaryAlertMetricStore {
        func find(_ code: String) -> PrimaryAlertMetric?
        func save(_ item: PrimaryAlertMetric)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryAlertMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryAlertMetricStore: PrimaryAlertMetricStore {
        var items: [String: PrimaryAlertMetric]
        var order: [String]

        init(items: [String: PrimaryAlertMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryAlertMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryAlertMetric) {
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

        func list() -> [PrimaryAlertMetric] {
            var out: [PrimaryAlertMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryAlertMetricStore() -> any PrimaryAlertMetricStore {
        return MemoryPrimaryAlertMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryAlertMetricStore: PrimaryAlertMetricStore {
        var inner: MemoryPrimaryAlertMetricStore
        var cache: TTLCache<PrimaryAlertMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryAlertMetricStore, cache: TTLCache<PrimaryAlertMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryAlertMetric? {
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

        func save(_ item: PrimaryAlertMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryAlertMetric] {
            return inner.list()
        }
    }

    static func newCachedPrimaryAlertMetricStore(_ inner: MemoryPrimaryAlertMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryAlertMetricStore {
        return CachedPrimaryAlertMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary alert metrics. Empty fields match all.
    final class PrimaryAlertMetricQuery {
        var category: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minSequence: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryAlertMetric) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryAlertMetric]) -> [PrimaryAlertMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryAlertMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryAlertMetrics(_ store: any PrimaryAlertMetricStore, query: PrimaryAlertMetricQuery) -> [PrimaryAlertMetric] {
        return query.apply(store.list())
    }
}
