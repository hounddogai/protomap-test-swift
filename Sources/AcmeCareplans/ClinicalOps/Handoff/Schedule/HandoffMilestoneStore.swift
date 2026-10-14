import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff milestones by code.
    protocol HandoffMilestoneStore {
        func find(_ code: String) -> HandoffMilestone?
        func save(_ item: HandoffMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffMilestoneStore: HandoffMilestoneStore {
        var items: [String: HandoffMilestone]
        var order: [String]

        init(items: [String: HandoffMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffMilestone) {
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

        func list() -> [HandoffMilestone] {
            var out: [HandoffMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffMilestoneStore() -> any HandoffMilestoneStore {
        return MemoryHandoffMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffMilestoneStore: HandoffMilestoneStore {
        var inner: MemoryHandoffMilestoneStore
        var cache: TTLCache<HandoffMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffMilestoneStore, cache: TTLCache<HandoffMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffMilestone? {
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

        func save(_ item: HandoffMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffMilestone] {
            return inner.list()
        }
    }

    static func newCachedHandoffMilestoneStore(_ inner: MemoryHandoffMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffMilestoneStore {
        return CachedHandoffMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff milestones. Empty fields match all.
    final class HandoffMilestoneQuery {
        var category: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minRate: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffMilestone) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [HandoffMilestone]) -> [HandoffMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffMilestones(_ store: any HandoffMilestoneStore, query: HandoffMilestoneQuery) -> [HandoffMilestone] {
        return query.apply(store.list())
    }
}
