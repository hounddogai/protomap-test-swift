import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction milestones by code.
    protocol InteractionMilestoneStore {
        func find(_ code: String) -> InteractionMilestone?
        func save(_ item: InteractionMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionMilestoneStore: InteractionMilestoneStore {
        var items: [String: InteractionMilestone]
        var order: [String]

        init(items: [String: InteractionMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionMilestone) {
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

        func list() -> [InteractionMilestone] {
            var out: [InteractionMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionMilestoneStore() -> any InteractionMilestoneStore {
        return MemoryInteractionMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionMilestoneStore: InteractionMilestoneStore {
        var inner: MemoryInteractionMilestoneStore
        var cache: TTLCache<InteractionMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionMilestoneStore, cache: TTLCache<InteractionMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionMilestone? {
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

        func save(_ item: InteractionMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionMilestone] {
            return inner.list()
        }
    }

    static func newCachedInteractionMilestoneStore(_ inner: MemoryInteractionMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionMilestoneStore {
        return CachedInteractionMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction milestones. Empty fields match all.
    final class InteractionMilestoneQuery {
        var name: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionMilestone) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionMilestone]) -> [InteractionMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionMilestones(_ store: any InteractionMilestoneStore, query: InteractionMilestoneQuery) -> [InteractionMilestone] {
        return query.apply(store.list())
    }
}
