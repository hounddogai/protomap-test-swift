import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix profiles by code.
    protocol SkillMixProfileStore {
        func find(_ code: String) -> SkillMixProfile?
        func save(_ item: SkillMixProfile)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixProfileStore: SkillMixProfileStore {
        var items: [String: SkillMixProfile]
        var order: [String]

        init(items: [String: SkillMixProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixProfile) {
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

        func list() -> [SkillMixProfile] {
            var out: [SkillMixProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixProfileStore() -> any SkillMixProfileStore {
        return MemorySkillMixProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixProfileStore: SkillMixProfileStore {
        var inner: MemorySkillMixProfileStore
        var cache: TTLCache<SkillMixProfile>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixProfileStore, cache: TTLCache<SkillMixProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixProfile? {
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

        func save(_ item: SkillMixProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixProfile] {
            return inner.list()
        }
    }

    static func newCachedSkillMixProfileStore(_ inner: MemorySkillMixProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixProfileStore {
        return CachedSkillMixProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix profiles. Empty fields match all.
    final class SkillMixProfileQuery {
        var name: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixProfile) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixProfile]) -> [SkillMixProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixProfiles(_ store: any SkillMixProfileStore, query: SkillMixProfileQuery) -> [SkillMixProfile] {
        return query.apply(store.list())
    }
}
