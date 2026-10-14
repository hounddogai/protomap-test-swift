import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps rolling care gap schedules by code.
    protocol RollingCareGapScheduleStore {
        func find(_ code: String) -> RollingCareGapSchedule?
        func save(_ item: RollingCareGapSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [RollingCareGapSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingCareGapScheduleStore: RollingCareGapScheduleStore {
        var items: [String: RollingCareGapSchedule]
        var order: [String]

        init(items: [String: RollingCareGapSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingCareGapSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingCareGapSchedule) {
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

        func list() -> [RollingCareGapSchedule] {
            var out: [RollingCareGapSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingCareGapScheduleStore() -> any RollingCareGapScheduleStore {
        return MemoryRollingCareGapScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingCareGapScheduleStore: RollingCareGapScheduleStore {
        var inner: MemoryRollingCareGapScheduleStore
        var cache: TTLCache<RollingCareGapSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingCareGapScheduleStore, cache: TTLCache<RollingCareGapSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingCareGapSchedule? {
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

        func save(_ item: RollingCareGapSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingCareGapSchedule] {
            return inner.list()
        }
    }

    static func newCachedRollingCareGapScheduleStore(_ inner: MemoryRollingCareGapScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingCareGapScheduleStore {
        return CachedRollingCareGapScheduleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling care gap schedules. Empty fields match all.
    final class RollingCareGapScheduleQuery {
        var title: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingCareGapSchedule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [RollingCareGapSchedule]) -> [RollingCareGapSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingCareGapSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingCareGapSchedules(_ store: any RollingCareGapScheduleStore, query: RollingCareGapScheduleQuery) -> [RollingCareGapSchedule] {
        return query.apply(store.list())
    }
}
