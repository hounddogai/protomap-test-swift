import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps manual skill mix milestones by code.
    protocol ManualSkillMixMilestoneStore {
        func find(_ code: String) -> ManualSkillMixMilestone?
        func save(_ item: ManualSkillMixMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ManualSkillMixMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualSkillMixMilestoneStore: ManualSkillMixMilestoneStore {
        var items: [String: ManualSkillMixMilestone]
        var order: [String]

        init(items: [String: ManualSkillMixMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualSkillMixMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualSkillMixMilestone) {
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

        func list() -> [ManualSkillMixMilestone] {
            var out: [ManualSkillMixMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualSkillMixMilestoneStore() -> any ManualSkillMixMilestoneStore {
        return MemoryManualSkillMixMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualSkillMixMilestoneStore: ManualSkillMixMilestoneStore {
        var inner: MemoryManualSkillMixMilestoneStore
        var cache: TTLCache<ManualSkillMixMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualSkillMixMilestoneStore, cache: TTLCache<ManualSkillMixMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualSkillMixMilestone? {
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

        func save(_ item: ManualSkillMixMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualSkillMixMilestone] {
            return inner.list()
        }
    }

    static func newCachedManualSkillMixMilestoneStore(_ inner: MemoryManualSkillMixMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualSkillMixMilestoneStore {
        return CachedManualSkillMixMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual skill mix milestones. Empty fields match all.
    final class ManualSkillMixMilestoneQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualSkillMixMilestone) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualSkillMixMilestone]) -> [ManualSkillMixMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualSkillMixMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualSkillMixMilestones(_ store: any ManualSkillMixMilestoneStore, query: ManualSkillMixMilestoneQuery) -> [ManualSkillMixMilestone] {
        return query.apply(store.list())
    }
}
