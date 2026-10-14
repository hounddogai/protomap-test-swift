import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps seasonal handoff milestones by code.
    protocol SeasonalHandoffMilestoneStore {
        func find(_ code: String) -> SeasonalHandoffMilestone?
        func save(_ item: SeasonalHandoffMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalHandoffMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalHandoffMilestoneStore: SeasonalHandoffMilestoneStore {
        var items: [String: SeasonalHandoffMilestone]
        var order: [String]

        init(items: [String: SeasonalHandoffMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalHandoffMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalHandoffMilestone) {
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

        func list() -> [SeasonalHandoffMilestone] {
            var out: [SeasonalHandoffMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalHandoffMilestoneStore() -> any SeasonalHandoffMilestoneStore {
        return MemorySeasonalHandoffMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalHandoffMilestoneStore: SeasonalHandoffMilestoneStore {
        var inner: MemorySeasonalHandoffMilestoneStore
        var cache: TTLCache<SeasonalHandoffMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalHandoffMilestoneStore, cache: TTLCache<SeasonalHandoffMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalHandoffMilestone? {
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

        func save(_ item: SeasonalHandoffMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalHandoffMilestone] {
            return inner.list()
        }
    }

    static func newCachedSeasonalHandoffMilestoneStore(_ inner: MemorySeasonalHandoffMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalHandoffMilestoneStore {
        return CachedSeasonalHandoffMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal handoff milestones. Empty fields match all.
    final class SeasonalHandoffMilestoneQuery {
        var label: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minScore: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalHandoffMilestone) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [SeasonalHandoffMilestone]) -> [SeasonalHandoffMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalHandoffMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalHandoffMilestones(_ store: any SeasonalHandoffMilestoneStore, query: SeasonalHandoffMilestoneQuery) -> [SeasonalHandoffMilestone] {
        return query.apply(store.list())
    }
}
