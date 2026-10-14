import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix variances by code.
    protocol SkillMixVarianceStore {
        func find(_ code: String) -> SkillMixVariance?
        func save(_ item: SkillMixVariance)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixVariance]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixVarianceStore: SkillMixVarianceStore {
        var items: [String: SkillMixVariance]
        var order: [String]

        init(items: [String: SkillMixVariance], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixVariance? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixVariance) {
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

        func list() -> [SkillMixVariance] {
            var out: [SkillMixVariance] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixVarianceStore() -> any SkillMixVarianceStore {
        return MemorySkillMixVarianceStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixVarianceStore: SkillMixVarianceStore {
        var inner: MemorySkillMixVarianceStore
        var cache: TTLCache<SkillMixVariance>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixVarianceStore, cache: TTLCache<SkillMixVariance>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixVariance? {
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

        func save(_ item: SkillMixVariance) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixVariance] {
            return inner.list()
        }
    }

    static func newCachedSkillMixVarianceStore(_ inner: MemorySkillMixVarianceStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixVarianceStore {
        return CachedSkillMixVarianceStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix variances. Empty fields match all.
    final class SkillMixVarianceQuery {
        var name: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minWeight: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixVariance) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixVariance]) -> [SkillMixVariance] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixVariance) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixVariances(_ store: any SkillMixVarianceStore, query: SkillMixVarianceQuery) -> [SkillMixVariance] {
        return query.apply(store.list())
    }
}
