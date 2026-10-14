import AcmePlatform
import Foundation

extension Consent {
    /// Keeps scheduled witness milestones by code.
    protocol ScheduledWitnessMilestoneStore {
        func find(_ code: String) -> ScheduledWitnessMilestone?
        func save(_ item: ScheduledWitnessMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledWitnessMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledWitnessMilestoneStore: ScheduledWitnessMilestoneStore {
        var items: [String: ScheduledWitnessMilestone]
        var order: [String]

        init(items: [String: ScheduledWitnessMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledWitnessMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledWitnessMilestone) {
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

        func list() -> [ScheduledWitnessMilestone] {
            var out: [ScheduledWitnessMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledWitnessMilestoneStore() -> any ScheduledWitnessMilestoneStore {
        return MemoryScheduledWitnessMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledWitnessMilestoneStore: ScheduledWitnessMilestoneStore {
        var inner: MemoryScheduledWitnessMilestoneStore
        var cache: TTLCache<ScheduledWitnessMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledWitnessMilestoneStore, cache: TTLCache<ScheduledWitnessMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledWitnessMilestone? {
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

        func save(_ item: ScheduledWitnessMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledWitnessMilestone] {
            return inner.list()
        }
    }

    static func newCachedScheduledWitnessMilestoneStore(_ inner: MemoryScheduledWitnessMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledWitnessMilestoneStore {
        return CachedScheduledWitnessMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled witness milestones. Empty fields match all.
    final class ScheduledWitnessMilestoneQuery {
        var unit: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minVersion: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledWitnessMilestone) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledWitnessMilestone]) -> [ScheduledWitnessMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledWitnessMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledWitnessMilestones(_ store: any ScheduledWitnessMilestoneStore, query: ScheduledWitnessMilestoneQuery) -> [ScheduledWitnessMilestone] {
        return query.apply(store.list())
    }
}
