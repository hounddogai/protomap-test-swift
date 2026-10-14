import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps overtime schedules by code.
    protocol OvertimeScheduleStore {
        func find(_ code: String) -> OvertimeSchedule?
        func save(_ item: OvertimeSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [OvertimeSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOvertimeScheduleStore: OvertimeScheduleStore {
        var items: [String: OvertimeSchedule]
        var order: [String]

        init(items: [String: OvertimeSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OvertimeSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OvertimeSchedule) {
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

        func list() -> [OvertimeSchedule] {
            var out: [OvertimeSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOvertimeScheduleStore() -> any OvertimeScheduleStore {
        return MemoryOvertimeScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOvertimeScheduleStore: OvertimeScheduleStore {
        var inner: MemoryOvertimeScheduleStore
        var cache: TTLCache<OvertimeSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryOvertimeScheduleStore, cache: TTLCache<OvertimeSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OvertimeSchedule? {
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

        func save(_ item: OvertimeSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OvertimeSchedule] {
            return inner.list()
        }
    }

    static func newCachedOvertimeScheduleStore(_ inner: MemoryOvertimeScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OvertimeScheduleStore {
        return CachedOvertimeScheduleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects overtime schedules. Empty fields match all.
    final class OvertimeScheduleQuery {
        var title: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMargin: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OvertimeSchedule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OvertimeSchedule]) -> [OvertimeSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OvertimeSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOvertimeSchedules(_ store: any OvertimeScheduleStore, query: OvertimeScheduleQuery) -> [OvertimeSchedule] {
        return query.apply(store.list())
    }
}
