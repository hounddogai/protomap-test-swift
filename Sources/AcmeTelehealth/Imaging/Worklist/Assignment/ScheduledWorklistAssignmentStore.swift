import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps scheduled worklist assignments by code.
    protocol ScheduledWorklistAssignmentStore {
        func find(_ code: String) -> ScheduledWorklistAssignment?
        func save(_ item: ScheduledWorklistAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledWorklistAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledWorklistAssignmentStore: ScheduledWorklistAssignmentStore {
        var items: [String: ScheduledWorklistAssignment]
        var order: [String]

        init(items: [String: ScheduledWorklistAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledWorklistAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledWorklistAssignment) {
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

        func list() -> [ScheduledWorklistAssignment] {
            var out: [ScheduledWorklistAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledWorklistAssignmentStore() -> any ScheduledWorklistAssignmentStore {
        return MemoryScheduledWorklistAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledWorklistAssignmentStore: ScheduledWorklistAssignmentStore {
        var inner: MemoryScheduledWorklistAssignmentStore
        var cache: TTLCache<ScheduledWorklistAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledWorklistAssignmentStore, cache: TTLCache<ScheduledWorklistAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledWorklistAssignment? {
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

        func save(_ item: ScheduledWorklistAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledWorklistAssignment] {
            return inner.list()
        }
    }

    static func newCachedScheduledWorklistAssignmentStore(_ inner: MemoryScheduledWorklistAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledWorklistAssignmentStore {
        return CachedScheduledWorklistAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled worklist assignments. Empty fields match all.
    final class ScheduledWorklistAssignmentQuery {
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

        func matches(_ item: ScheduledWorklistAssignment) -> Bool {
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

        func apply(_ items: [ScheduledWorklistAssignment]) -> [ScheduledWorklistAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledWorklistAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledWorklistAssignments(_ store: any ScheduledWorklistAssignmentStore, query: ScheduledWorklistAssignmentQuery) -> [ScheduledWorklistAssignment] {
        return query.apply(store.list())
    }
}
