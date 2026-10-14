import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps rolling bed board schedules by code.
    protocol RollingBedBoardScheduleStore {
        func find(_ code: String) -> RollingBedBoardSchedule?
        func save(_ item: RollingBedBoardSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [RollingBedBoardSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingBedBoardScheduleStore: RollingBedBoardScheduleStore {
        var items: [String: RollingBedBoardSchedule]
        var order: [String]

        init(items: [String: RollingBedBoardSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingBedBoardSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingBedBoardSchedule) {
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

        func list() -> [RollingBedBoardSchedule] {
            var out: [RollingBedBoardSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingBedBoardScheduleStore() -> any RollingBedBoardScheduleStore {
        return MemoryRollingBedBoardScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingBedBoardScheduleStore: RollingBedBoardScheduleStore {
        var inner: MemoryRollingBedBoardScheduleStore
        var cache: TTLCache<RollingBedBoardSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingBedBoardScheduleStore, cache: TTLCache<RollingBedBoardSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingBedBoardSchedule? {
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

        func save(_ item: RollingBedBoardSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingBedBoardSchedule] {
            return inner.list()
        }
    }

    static func newCachedRollingBedBoardScheduleStore(_ inner: MemoryRollingBedBoardScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingBedBoardScheduleStore {
        return CachedRollingBedBoardScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling bed board schedules. Empty fields match all.
    final class RollingBedBoardScheduleQuery {
        var segment: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingBedBoardSchedule) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingBedBoardSchedule]) -> [RollingBedBoardSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingBedBoardSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingBedBoardSchedules(_ store: any RollingBedBoardScheduleStore, query: RollingBedBoardScheduleQuery) -> [RollingBedBoardSchedule] {
        return query.apply(store.list())
    }
}
