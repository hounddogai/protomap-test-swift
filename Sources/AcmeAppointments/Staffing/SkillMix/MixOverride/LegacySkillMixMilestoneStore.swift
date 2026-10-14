import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps legacy skill mix milestones by code.
    protocol LegacySkillMixMilestoneStore {
        func find(_ code: String) -> LegacySkillMixMilestone?
        func save(_ item: LegacySkillMixMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [LegacySkillMixMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacySkillMixMilestoneStore: LegacySkillMixMilestoneStore {
        var items: [String: LegacySkillMixMilestone]
        var order: [String]

        init(items: [String: LegacySkillMixMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacySkillMixMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacySkillMixMilestone) {
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

        func list() -> [LegacySkillMixMilestone] {
            var out: [LegacySkillMixMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacySkillMixMilestoneStore() -> any LegacySkillMixMilestoneStore {
        return MemoryLegacySkillMixMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacySkillMixMilestoneStore: LegacySkillMixMilestoneStore {
        var inner: MemoryLegacySkillMixMilestoneStore
        var cache: TTLCache<LegacySkillMixMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacySkillMixMilestoneStore, cache: TTLCache<LegacySkillMixMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacySkillMixMilestone? {
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

        func save(_ item: LegacySkillMixMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacySkillMixMilestone] {
            return inner.list()
        }
    }

    static func newCachedLegacySkillMixMilestoneStore(_ inner: MemoryLegacySkillMixMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacySkillMixMilestoneStore {
        return CachedLegacySkillMixMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy skill mix milestones. Empty fields match all.
    final class LegacySkillMixMilestoneQuery {
        var locale: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minWeight: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacySkillMixMilestone) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [LegacySkillMixMilestone]) -> [LegacySkillMixMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacySkillMixMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacySkillMixMilestones(_ store: any LegacySkillMixMilestoneStore, query: LegacySkillMixMilestoneQuery) -> [LegacySkillMixMilestone] {
        return query.apply(store.list())
    }
}
