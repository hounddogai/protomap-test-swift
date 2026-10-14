import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps scheduled goal segments by code.
    protocol ScheduledGoalSegmentStore {
        func find(_ code: String) -> ScheduledGoalSegment?
        func save(_ item: ScheduledGoalSegment)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledGoalSegment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledGoalSegmentStore: ScheduledGoalSegmentStore {
        var items: [String: ScheduledGoalSegment]
        var order: [String]

        init(items: [String: ScheduledGoalSegment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledGoalSegment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledGoalSegment) {
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

        func list() -> [ScheduledGoalSegment] {
            var out: [ScheduledGoalSegment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledGoalSegmentStore() -> any ScheduledGoalSegmentStore {
        return MemoryScheduledGoalSegmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledGoalSegmentStore: ScheduledGoalSegmentStore {
        var inner: MemoryScheduledGoalSegmentStore
        var cache: TTLCache<ScheduledGoalSegment>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledGoalSegmentStore, cache: TTLCache<ScheduledGoalSegment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledGoalSegment? {
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

        func save(_ item: ScheduledGoalSegment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledGoalSegment] {
            return inner.list()
        }
    }

    static func newCachedScheduledGoalSegmentStore(_ inner: MemoryScheduledGoalSegmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledGoalSegmentStore {
        return CachedScheduledGoalSegmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled goal segments. Empty fields match all.
    final class ScheduledGoalSegmentQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledGoalSegment) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledGoalSegment]) -> [ScheduledGoalSegment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledGoalSegment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledGoalSegments(_ store: any ScheduledGoalSegmentStore, query: ScheduledGoalSegmentQuery) -> [ScheduledGoalSegment] {
        return query.apply(store.list())
    }
}
