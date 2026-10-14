import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict task milestones by code.
    protocol StrictTaskMilestoneStore {
        func find(_ code: String) -> StrictTaskMilestone?
        func save(_ item: StrictTaskMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [StrictTaskMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictTaskMilestoneStore: StrictTaskMilestoneStore {
        var items: [String: StrictTaskMilestone]
        var order: [String]

        init(items: [String: StrictTaskMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictTaskMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictTaskMilestone) {
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

        func list() -> [StrictTaskMilestone] {
            var out: [StrictTaskMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictTaskMilestoneStore() -> any StrictTaskMilestoneStore {
        return MemoryStrictTaskMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictTaskMilestoneStore: StrictTaskMilestoneStore {
        var inner: MemoryStrictTaskMilestoneStore
        var cache: TTLCache<StrictTaskMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictTaskMilestoneStore, cache: TTLCache<StrictTaskMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictTaskMilestone? {
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

        func save(_ item: StrictTaskMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictTaskMilestone] {
            return inner.list()
        }
    }

    static func newCachedStrictTaskMilestoneStore(_ inner: MemoryStrictTaskMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictTaskMilestoneStore {
        return CachedStrictTaskMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict task milestones. Empty fields match all.
    final class StrictTaskMilestoneQuery {
        var title: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minScore: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictTaskMilestone) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [StrictTaskMilestone]) -> [StrictTaskMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictTaskMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictTaskMilestones(_ store: any StrictTaskMilestoneStore, query: StrictTaskMilestoneQuery) -> [StrictTaskMilestone] {
        return query.apply(store.list())
    }
}
