import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime milestones by code.
    protocol OvertimeMilestoneStore {
        func find(_ code: String) -> OvertimeMilestone?
        func save(_ item: OvertimeMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeMilestoneStore: OvertimeMilestoneStore {
        var items: [String: OvertimeMilestone]
        var order: [String]

        init(items: [String: OvertimeMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeMilestone) {
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

        func list() -> [OvertimeMilestone] {
            var out: [OvertimeMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeMilestoneStore() -> any OvertimeMilestoneStore {
        return MemoryOvertimeMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeMilestoneStore: OvertimeMilestoneStore {
        var inner: MemoryOvertimeMilestoneStore
        var cache: TTLCache<OvertimeMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeMilestoneStore, cache: TTLCache<OvertimeMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeMilestone? {
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

        func save(_ item: OvertimeMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeMilestone] {
            return inner.list()
        }
    }

    static func newCachedOvertimeMilestoneStore(_ inner: MemoryOvertimeMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeMilestoneStore {
        return CachedOvertimeMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime milestones. Empty fields match all.
    final class OvertimeMilestoneQuery {
        var unit: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeMilestone) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeMilestone]) -> [OvertimeMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeMilestones(_ store: any OvertimeMilestoneStore, query: OvertimeMilestoneQuery) -> [OvertimeMilestone] {
        return query.apply(store.list())
    }
}
