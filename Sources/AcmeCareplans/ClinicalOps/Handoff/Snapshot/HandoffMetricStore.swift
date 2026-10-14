import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff metrics by code.
    protocol HandoffMetricStore {
        func find(_ code: String) -> HandoffMetric?
        func save(_ item: HandoffMetric)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffMetricStore: HandoffMetricStore {
        var items: [String: HandoffMetric]
        var order: [String]

        init(items: [String: HandoffMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffMetric) {
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

        func list() -> [HandoffMetric] {
            var out: [HandoffMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffMetricStore() -> any HandoffMetricStore {
        return MemoryHandoffMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffMetricStore: HandoffMetricStore {
        var inner: MemoryHandoffMetricStore
        var cache: TTLCache<HandoffMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffMetricStore, cache: TTLCache<HandoffMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffMetric? {
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

        func save(_ item: HandoffMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffMetric] {
            return inner.list()
        }
    }

    static func newCachedHandoffMetricStore(_ inner: MemoryHandoffMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffMetricStore {
        return CachedHandoffMetricStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff metrics. Empty fields match all.
    final class HandoffMetricQuery {
        var ward: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffMetric) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffMetric]) -> [HandoffMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffMetrics(_ store: any HandoffMetricStore, query: HandoffMetricQuery) -> [HandoffMetric] {
        return query.apply(store.list())
    }
}
