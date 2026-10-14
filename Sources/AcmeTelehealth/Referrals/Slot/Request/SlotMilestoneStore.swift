import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps slot milestones by code.
    protocol SlotMilestoneStore {
        func find(_ code: String) -> SlotMilestone?
        func save(_ item: SlotMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [SlotMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySlotMilestoneStore: SlotMilestoneStore {
        var items: [String: SlotMilestone]
        var order: [String]

        init(items: [String: SlotMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SlotMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SlotMilestone) {
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

        func list() -> [SlotMilestone] {
            var out: [SlotMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySlotMilestoneStore() -> any SlotMilestoneStore {
        return MemorySlotMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSlotMilestoneStore: SlotMilestoneStore {
        var inner: MemorySlotMilestoneStore
        var cache: TTLCache<SlotMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemorySlotMilestoneStore, cache: TTLCache<SlotMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SlotMilestone? {
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

        func save(_ item: SlotMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SlotMilestone] {
            return inner.list()
        }
    }

    static func newCachedSlotMilestoneStore(_ inner: MemorySlotMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SlotMilestoneStore {
        return CachedSlotMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects slot milestones. Empty fields match all.
    final class SlotMilestoneQuery {
        var category: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minRatio: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SlotMilestone) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [SlotMilestone]) -> [SlotMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SlotMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSlotMilestones(_ store: any SlotMilestoneStore, query: SlotMilestoneQuery) -> [SlotMilestone] {
        return query.apply(store.list())
    }
}
