import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps rolling cleaning assignments by code.
    protocol RollingCleaningAssignmentStore {
        func find(_ code: String) -> RollingCleaningAssignment?
        func save(_ item: RollingCleaningAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [RollingCleaningAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingCleaningAssignmentStore: RollingCleaningAssignmentStore {
        var items: [String: RollingCleaningAssignment]
        var order: [String]

        init(items: [String: RollingCleaningAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingCleaningAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingCleaningAssignment) {
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

        func list() -> [RollingCleaningAssignment] {
            var out: [RollingCleaningAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingCleaningAssignmentStore() -> any RollingCleaningAssignmentStore {
        return MemoryRollingCleaningAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingCleaningAssignmentStore: RollingCleaningAssignmentStore {
        var inner: MemoryRollingCleaningAssignmentStore
        var cache: TTLCache<RollingCleaningAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingCleaningAssignmentStore, cache: TTLCache<RollingCleaningAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingCleaningAssignment? {
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

        func save(_ item: RollingCleaningAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingCleaningAssignment] {
            return inner.list()
        }
    }

    static func newCachedRollingCleaningAssignmentStore(_ inner: MemoryRollingCleaningAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingCleaningAssignmentStore {
        return CachedRollingCleaningAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling cleaning assignments. Empty fields match all.
    final class RollingCleaningAssignmentQuery {
        var channel: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minRate: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingCleaningAssignment) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [RollingCleaningAssignment]) -> [RollingCleaningAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingCleaningAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingCleaningAssignments(_ store: any RollingCleaningAssignmentStore, query: RollingCleaningAssignmentQuery) -> [RollingCleaningAssignment] {
        return query.apply(store.list())
    }
}
