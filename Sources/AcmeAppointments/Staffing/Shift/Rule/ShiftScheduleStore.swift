import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps shift schedules by code.
    protocol ShiftScheduleStore {
        func find(_ code: String) -> ShiftSchedule?
        func save(_ item: ShiftSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [ShiftSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryShiftScheduleStore: ShiftScheduleStore {
        var items: [String: ShiftSchedule]
        var order: [String]

        init(items: [String: ShiftSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ShiftSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ShiftSchedule) {
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

        func list() -> [ShiftSchedule] {
            var out: [ShiftSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryShiftScheduleStore() -> any ShiftScheduleStore {
        return MemoryShiftScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedShiftScheduleStore: ShiftScheduleStore {
        var inner: MemoryShiftScheduleStore
        var cache: TTLCache<ShiftSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryShiftScheduleStore, cache: TTLCache<ShiftSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ShiftSchedule? {
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

        func save(_ item: ShiftSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ShiftSchedule] {
            return inner.list()
        }
    }

    static func newCachedShiftScheduleStore(_ inner: MemoryShiftScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ShiftScheduleStore {
        return CachedShiftScheduleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects shift schedules. Empty fields match all.
    final class ShiftScheduleQuery {
        var region: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minVersion: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ShiftSchedule) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [ShiftSchedule]) -> [ShiftSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ShiftSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findShiftSchedules(_ store: any ShiftScheduleStore, query: ShiftScheduleQuery) -> [ShiftSchedule] {
        return query.apply(store.list())
    }
}
