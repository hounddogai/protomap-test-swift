import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps global follow up metrics by code.
    protocol GlobalFollowUpMetricStore {
        func find(_ code: String) -> GlobalFollowUpMetric?
        func save(_ item: GlobalFollowUpMetric)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalFollowUpMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalFollowUpMetricStore: GlobalFollowUpMetricStore {
        var items: [String: GlobalFollowUpMetric]
        var order: [String]

        init(items: [String: GlobalFollowUpMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalFollowUpMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalFollowUpMetric) {
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

        func list() -> [GlobalFollowUpMetric] {
            var out: [GlobalFollowUpMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalFollowUpMetricStore() -> any GlobalFollowUpMetricStore {
        return MemoryGlobalFollowUpMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalFollowUpMetricStore: GlobalFollowUpMetricStore {
        var inner: MemoryGlobalFollowUpMetricStore
        var cache: TTLCache<GlobalFollowUpMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalFollowUpMetricStore, cache: TTLCache<GlobalFollowUpMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalFollowUpMetric? {
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

        func save(_ item: GlobalFollowUpMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalFollowUpMetric] {
            return inner.list()
        }
    }

    static func newCachedGlobalFollowUpMetricStore(_ inner: MemoryGlobalFollowUpMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalFollowUpMetricStore {
        return CachedGlobalFollowUpMetricStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global follow up metrics. Empty fields match all.
    final class GlobalFollowUpMetricQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalFollowUpMetric) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalFollowUpMetric]) -> [GlobalFollowUpMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalFollowUpMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalFollowUpMetrics(_ store: any GlobalFollowUpMetricStore, query: GlobalFollowUpMetricQuery) -> [GlobalFollowUpMetric] {
        return query.apply(store.list())
    }
}
