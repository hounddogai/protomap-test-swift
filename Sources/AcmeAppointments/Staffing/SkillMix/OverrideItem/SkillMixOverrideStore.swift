import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix overrides by code.
    protocol SkillMixOverrideStore {
        func find(_ code: String) -> SkillMixOverride?
        func save(_ item: SkillMixOverride)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixOverrideStore: SkillMixOverrideStore {
        var items: [String: SkillMixOverride]
        var order: [String]

        init(items: [String: SkillMixOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixOverride) {
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

        func list() -> [SkillMixOverride] {
            var out: [SkillMixOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixOverrideStore() -> any SkillMixOverrideStore {
        return MemorySkillMixOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixOverrideStore: SkillMixOverrideStore {
        var inner: MemorySkillMixOverrideStore
        var cache: TTLCache<SkillMixOverride>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixOverrideStore, cache: TTLCache<SkillMixOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixOverride? {
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

        func save(_ item: SkillMixOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixOverride] {
            return inner.list()
        }
    }

    static func newCachedSkillMixOverrideStore(_ inner: MemorySkillMixOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixOverrideStore {
        return CachedSkillMixOverrideStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix overrides. Empty fields match all.
    final class SkillMixOverrideQuery {
        var title: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minRevision: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixOverride) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixOverride]) -> [SkillMixOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixOverrides(_ store: any SkillMixOverrideStore, query: SkillMixOverrideQuery) -> [SkillMixOverride] {
        return query.apply(store.list())
    }
}
