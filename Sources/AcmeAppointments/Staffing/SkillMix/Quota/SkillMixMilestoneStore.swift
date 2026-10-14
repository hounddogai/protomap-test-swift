import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps skill mix milestones by code.
    protocol SkillMixMilestoneStore {
        func find(_ code: String) -> SkillMixMilestone?
        func save(_ item: SkillMixMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [SkillMixMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySkillMixMilestoneStore: SkillMixMilestoneStore {
        var items: [String: SkillMixMilestone]
        var order: [String]

        init(items: [String: SkillMixMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SkillMixMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SkillMixMilestone) {
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

        func list() -> [SkillMixMilestone] {
            var out: [SkillMixMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySkillMixMilestoneStore() -> any SkillMixMilestoneStore {
        return MemorySkillMixMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSkillMixMilestoneStore: SkillMixMilestoneStore {
        var inner: MemorySkillMixMilestoneStore
        var cache: TTLCache<SkillMixMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemorySkillMixMilestoneStore, cache: TTLCache<SkillMixMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SkillMixMilestone? {
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

        func save(_ item: SkillMixMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SkillMixMilestone] {
            return inner.list()
        }
    }

    static func newCachedSkillMixMilestoneStore(_ inner: MemorySkillMixMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SkillMixMilestoneStore {
        return CachedSkillMixMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects skill mix milestones. Empty fields match all.
    final class SkillMixMilestoneQuery {
        var source: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SkillMixMilestone) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SkillMixMilestone]) -> [SkillMixMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SkillMixMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSkillMixMilestones(_ store: any SkillMixMilestoneStore, query: SkillMixMilestoneQuery) -> [SkillMixMilestone] {
        return query.apply(store.list())
    }
}
