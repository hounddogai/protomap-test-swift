import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix metrics by code.
    protocol SkillMixMetricStore {
        func find(_ code: String) -> SkillMixMetric?
        func save(_ item: SkillMixMetric)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixMetric]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixMetricStore: SkillMixMetricStore {
        var items: [String: SkillMixMetric]
        var order: [String]

        init(items: [String: SkillMixMetric], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixMetric? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixMetric) {
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

        func list() -> [SkillMixMetric] {
            var out: [SkillMixMetric] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixMetricStore() -> any SkillMixMetricStore {
        return MemorySkillMixMetricStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixMetricStore: SkillMixMetricStore {
        var inner: MemorySkillMixMetricStore
        var cache: TTLCache<SkillMixMetric>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixMetricStore, cache: TTLCache<SkillMixMetric>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixMetric? {
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

        func save(_ item: SkillMixMetric) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixMetric] {
            return inner.list()
        }
    }

    static func newCachedSkillMixMetricStore(_ inner: MemorySkillMixMetricStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixMetricStore {
        return CachedSkillMixMetricStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix metrics. Empty fields match all.
    final class SkillMixMetricQuery {
        var category: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixMetric) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixMetric]) -> [SkillMixMetric] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixMetric) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixMetrics(_ store: any SkillMixMetricStore, query: SkillMixMetricQuery) -> [SkillMixMetric] {
        return query.apply(store.list())
    }
}
