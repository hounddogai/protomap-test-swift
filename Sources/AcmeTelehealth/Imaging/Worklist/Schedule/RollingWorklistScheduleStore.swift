import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps rolling worklist schedules by code.
    protocol RollingWorklistScheduleStore {
        func find(_ code: String) -> RollingWorklistSchedule?
        func save(_ item: RollingWorklistSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [RollingWorklistSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingWorklistScheduleStore: RollingWorklistScheduleStore {
        var items: [String: RollingWorklistSchedule]
        var order: [String]

        init(items: [String: RollingWorklistSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingWorklistSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingWorklistSchedule) {
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

        func list() -> [RollingWorklistSchedule] {
            var out: [RollingWorklistSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingWorklistScheduleStore() -> any RollingWorklistScheduleStore {
        return MemoryRollingWorklistScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingWorklistScheduleStore: RollingWorklistScheduleStore {
        var inner: MemoryRollingWorklistScheduleStore
        var cache: TTLCache<RollingWorklistSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingWorklistScheduleStore, cache: TTLCache<RollingWorklistSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingWorklistSchedule? {
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

        func save(_ item: RollingWorklistSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingWorklistSchedule] {
            return inner.list()
        }
    }

    static func newCachedRollingWorklistScheduleStore(_ inner: MemoryRollingWorklistScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingWorklistScheduleStore {
        return CachedRollingWorklistScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling worklist schedules. Empty fields match all.
    final class RollingWorklistScheduleQuery {
        var locale: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingWorklistSchedule) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingWorklistSchedule]) -> [RollingWorklistSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingWorklistSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingWorklistSchedules(_ store: any RollingWorklistScheduleStore, query: RollingWorklistScheduleQuery) -> [RollingWorklistSchedule] {
        return query.apply(store.list())
    }
}
