import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps scheduled float pool assignments by code.
    protocol ScheduledFloatPoolAssignmentStore {
        func find(_ code: String) -> ScheduledFloatPoolAssignment?
        func save(_ item: ScheduledFloatPoolAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledFloatPoolAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledFloatPoolAssignmentStore: ScheduledFloatPoolAssignmentStore {
        var items: [String: ScheduledFloatPoolAssignment]
        var order: [String]

        init(items: [String: ScheduledFloatPoolAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledFloatPoolAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledFloatPoolAssignment) {
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

        func list() -> [ScheduledFloatPoolAssignment] {
            var out: [ScheduledFloatPoolAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledFloatPoolAssignmentStore() -> any ScheduledFloatPoolAssignmentStore {
        return MemoryScheduledFloatPoolAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledFloatPoolAssignmentStore: ScheduledFloatPoolAssignmentStore {
        var inner: MemoryScheduledFloatPoolAssignmentStore
        var cache: TTLCache<ScheduledFloatPoolAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledFloatPoolAssignmentStore, cache: TTLCache<ScheduledFloatPoolAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledFloatPoolAssignment? {
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

        func save(_ item: ScheduledFloatPoolAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledFloatPoolAssignment] {
            return inner.list()
        }
    }

    static func newCachedScheduledFloatPoolAssignmentStore(_ inner: MemoryScheduledFloatPoolAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledFloatPoolAssignmentStore {
        return CachedScheduledFloatPoolAssignmentStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled float pool assignments. Empty fields match all.
    final class ScheduledFloatPoolAssignmentQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledFloatPoolAssignment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledFloatPoolAssignment]) -> [ScheduledFloatPoolAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledFloatPoolAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledFloatPoolAssignments(_ store: any ScheduledFloatPoolAssignmentStore, query: ScheduledFloatPoolAssignmentQuery) -> [ScheduledFloatPoolAssignment] {
        return query.apply(store.list())
    }
}
