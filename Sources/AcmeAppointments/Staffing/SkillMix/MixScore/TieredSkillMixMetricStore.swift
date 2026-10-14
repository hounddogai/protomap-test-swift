import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps tiered skill mix metrics by code.
    protocol TieredSkillMixMetricStore {
        func find(_ code: String) -> TieredSkillMixMetric?
        func save(_ item: TieredSkillMixMetric)
        func remove(_ code: String) -> Bool
        func list() -> [TieredSkillMixMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredSkillMixMetricStore: TieredSkillMixMetricStore {
        var items: [String: TieredSkillMixMetric]
        var order: [String]

        init(items: [String: TieredSkillMixMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredSkillMixMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredSkillMixMetric) {
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

        func list() -> [TieredSkillMixMetric] {
            var out: [TieredSkillMixMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredSkillMixMetricStore() -> any TieredSkillMixMetricStore {
        return MemoryTieredSkillMixMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredSkillMixMetricStore: TieredSkillMixMetricStore {
        var inner: MemoryTieredSkillMixMetricStore
        var cache: TTLCache<TieredSkillMixMetric>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredSkillMixMetricStore, cache: TTLCache<TieredSkillMixMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredSkillMixMetric? {
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

        func save(_ item: TieredSkillMixMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredSkillMixMetric] {
            return inner.list()
        }
    }

    static func newCachedTieredSkillMixMetricStore(_ inner: MemoryTieredSkillMixMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredSkillMixMetricStore {
        return CachedTieredSkillMixMetricStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered skill mix metrics. Empty fields match all.
    final class TieredSkillMixMetricQuery {
        var unit: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredSkillMixMetric) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredSkillMixMetric]) -> [TieredSkillMixMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredSkillMixMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredSkillMixMetrics(_ store: any TieredSkillMixMetricStore, query: TieredSkillMixMetricQuery) -> [TieredSkillMixMetric] {
        return query.apply(store.list())
    }
}
