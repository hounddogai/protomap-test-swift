import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps scheduled cleaning assignments by code.
    protocol ScheduledCleaningAssignmentStore {
        func find(_ code: String) -> ScheduledCleaningAssignment?
        func save(_ item: ScheduledCleaningAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCleaningAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCleaningAssignmentStore: ScheduledCleaningAssignmentStore {
        var items: [String: ScheduledCleaningAssignment]
        var order: [String]

        init(items: [String: ScheduledCleaningAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCleaningAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCleaningAssignment) {
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

        func list() -> [ScheduledCleaningAssignment] {
            var out: [ScheduledCleaningAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCleaningAssignmentStore() -> any ScheduledCleaningAssignmentStore {
        return MemoryScheduledCleaningAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCleaningAssignmentStore: ScheduledCleaningAssignmentStore {
        var inner: MemoryScheduledCleaningAssignmentStore
        var cache: TTLCache<ScheduledCleaningAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCleaningAssignmentStore, cache: TTLCache<ScheduledCleaningAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCleaningAssignment? {
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

        func save(_ item: ScheduledCleaningAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCleaningAssignment] {
            return inner.list()
        }
    }

    static func newCachedScheduledCleaningAssignmentStore(_ inner: MemoryScheduledCleaningAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCleaningAssignmentStore {
        return CachedScheduledCleaningAssignmentStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled cleaning assignments. Empty fields match all.
    final class ScheduledCleaningAssignmentQuery {
        var name: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCleaningAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledCleaningAssignment]) -> [ScheduledCleaningAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCleaningAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCleaningAssignments(_ store: any ScheduledCleaningAssignmentStore, query: ScheduledCleaningAssignmentQuery) -> [ScheduledCleaningAssignment] {
        return query.apply(store.list())
    }
}
