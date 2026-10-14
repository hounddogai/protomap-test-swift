import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix rollups by code.
    protocol SkillMixRollupStore {
        func find(_ code: String) -> SkillMixRollup?
        func save(_ item: SkillMixRollup)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixRollup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixRollupStore: SkillMixRollupStore {
        var items: [String: SkillMixRollup]
        var order: [String]

        init(items: [String: SkillMixRollup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixRollup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixRollup) {
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

        func list() -> [SkillMixRollup] {
            var out: [SkillMixRollup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixRollupStore() -> any SkillMixRollupStore {
        return MemorySkillMixRollupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixRollupStore: SkillMixRollupStore {
        var inner: MemorySkillMixRollupStore
        var cache: TTLCache<SkillMixRollup>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixRollupStore, cache: TTLCache<SkillMixRollup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixRollup? {
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

        func save(_ item: SkillMixRollup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixRollup] {
            return inner.list()
        }
    }

    static func newCachedSkillMixRollupStore(_ inner: MemorySkillMixRollupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixRollupStore {
        return CachedSkillMixRollupStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix rollups. Empty fields match all.
    final class SkillMixRollupQuery {
        var name: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minVersion: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixRollup) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixRollup]) -> [SkillMixRollup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixRollup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixRollups(_ store: any SkillMixRollupStore, query: SkillMixRollupQuery) -> [SkillMixRollup] {
        return query.apply(store.list())
    }
}
