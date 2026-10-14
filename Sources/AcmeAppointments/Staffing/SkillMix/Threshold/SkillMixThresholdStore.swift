import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix thresholds by code.
    protocol SkillMixThresholdStore {
        func find(_ code: String) -> SkillMixThreshold?
        func save(_ item: SkillMixThreshold)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixThreshold]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixThresholdStore: SkillMixThresholdStore {
        var items: [String: SkillMixThreshold]
        var order: [String]

        init(items: [String: SkillMixThreshold], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixThreshold? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixThreshold) {
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

        func list() -> [SkillMixThreshold] {
            var out: [SkillMixThreshold] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixThresholdStore() -> any SkillMixThresholdStore {
        return MemorySkillMixThresholdStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixThresholdStore: SkillMixThresholdStore {
        var inner: MemorySkillMixThresholdStore
        var cache: TTLCache<SkillMixThreshold>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixThresholdStore, cache: TTLCache<SkillMixThreshold>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixThreshold? {
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

        func save(_ item: SkillMixThreshold) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixThreshold] {
            return inner.list()
        }
    }

    static func newCachedSkillMixThresholdStore(_ inner: MemorySkillMixThresholdStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixThresholdStore {
        return CachedSkillMixThresholdStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix thresholds. Empty fields match all.
    final class SkillMixThresholdQuery {
        var region: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixThreshold) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [SkillMixThreshold]) -> [SkillMixThreshold] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixThreshold) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixThresholds(_ store: any SkillMixThresholdStore, query: SkillMixThresholdQuery) -> [SkillMixThreshold] {
        return query.apply(store.list())
    }
}
