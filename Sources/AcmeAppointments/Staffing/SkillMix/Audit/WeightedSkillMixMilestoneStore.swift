import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps weighted skill mix milestones by code.
    protocol WeightedSkillMixMilestoneStore {
        func find(_ code: String) -> WeightedSkillMixMilestone?
        func save(_ item: WeightedSkillMixMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSkillMixMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSkillMixMilestoneStore: WeightedSkillMixMilestoneStore {
        var items: [String: WeightedSkillMixMilestone]
        var order: [String]

        init(items: [String: WeightedSkillMixMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSkillMixMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSkillMixMilestone) {
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

        func list() -> [WeightedSkillMixMilestone] {
            var out: [WeightedSkillMixMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSkillMixMilestoneStore() -> any WeightedSkillMixMilestoneStore {
        return MemoryWeightedSkillMixMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSkillMixMilestoneStore: WeightedSkillMixMilestoneStore {
        var inner: MemoryWeightedSkillMixMilestoneStore
        var cache: TTLCache<WeightedSkillMixMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSkillMixMilestoneStore, cache: TTLCache<WeightedSkillMixMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSkillMixMilestone? {
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

        func save(_ item: WeightedSkillMixMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSkillMixMilestone] {
            return inner.list()
        }
    }

    static func newCachedWeightedSkillMixMilestoneStore(_ inner: MemoryWeightedSkillMixMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSkillMixMilestoneStore {
        return CachedWeightedSkillMixMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted skill mix milestones. Empty fields match all.
    final class WeightedSkillMixMilestoneQuery {
        var name: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minScore: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedSkillMixMilestone) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedSkillMixMilestone]) -> [WeightedSkillMixMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSkillMixMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSkillMixMilestones(_ store: any WeightedSkillMixMilestoneStore, query: WeightedSkillMixMilestoneQuery) -> [WeightedSkillMixMilestone] {
        return query.apply(store.list())
    }
}
