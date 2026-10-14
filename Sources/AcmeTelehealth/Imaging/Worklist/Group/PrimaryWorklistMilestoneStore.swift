import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary worklist milestones by code.
    protocol PrimaryWorklistMilestoneStore {
        func find(_ code: String) -> PrimaryWorklistMilestone?
        func save(_ item: PrimaryWorklistMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryWorklistMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryWorklistMilestoneStore: PrimaryWorklistMilestoneStore {
        var items: [String: PrimaryWorklistMilestone]
        var order: [String]

        init(items: [String: PrimaryWorklistMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryWorklistMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryWorklistMilestone) {
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

        func list() -> [PrimaryWorklistMilestone] {
            var out: [PrimaryWorklistMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryWorklistMilestoneStore() -> any PrimaryWorklistMilestoneStore {
        return MemoryPrimaryWorklistMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryWorklistMilestoneStore: PrimaryWorklistMilestoneStore {
        var inner: MemoryPrimaryWorklistMilestoneStore
        var cache: TTLCache<PrimaryWorklistMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryWorklistMilestoneStore, cache: TTLCache<PrimaryWorklistMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryWorklistMilestone? {
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

        func save(_ item: PrimaryWorklistMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryWorklistMilestone] {
            return inner.list()
        }
    }

    static func newCachedPrimaryWorklistMilestoneStore(_ inner: MemoryPrimaryWorklistMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryWorklistMilestoneStore {
        return CachedPrimaryWorklistMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary worklist milestones. Empty fields match all.
    final class PrimaryWorklistMilestoneQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryWorklistMilestone) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryWorklistMilestone]) -> [PrimaryWorklistMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryWorklistMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryWorklistMilestones(_ store: any PrimaryWorklistMilestoneStore, query: PrimaryWorklistMilestoneQuery) -> [PrimaryWorklistMilestone] {
        return query.apply(store.list())
    }
}
