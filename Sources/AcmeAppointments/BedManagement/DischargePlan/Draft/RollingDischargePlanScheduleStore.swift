import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps rolling discharge plan schedules by code.
    protocol RollingDischargePlanScheduleStore {
        func find(_ code: String) -> RollingDischargePlanSchedule?
        func save(_ item: RollingDischargePlanSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [RollingDischargePlanSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingDischargePlanScheduleStore: RollingDischargePlanScheduleStore {
        var items: [String: RollingDischargePlanSchedule]
        var order: [String]

        init(items: [String: RollingDischargePlanSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingDischargePlanSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingDischargePlanSchedule) {
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

        func list() -> [RollingDischargePlanSchedule] {
            var out: [RollingDischargePlanSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingDischargePlanScheduleStore() -> any RollingDischargePlanScheduleStore {
        return MemoryRollingDischargePlanScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingDischargePlanScheduleStore: RollingDischargePlanScheduleStore {
        var inner: MemoryRollingDischargePlanScheduleStore
        var cache: TTLCache<RollingDischargePlanSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingDischargePlanScheduleStore, cache: TTLCache<RollingDischargePlanSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingDischargePlanSchedule? {
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

        func save(_ item: RollingDischargePlanSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingDischargePlanSchedule] {
            return inner.list()
        }
    }

    static func newCachedRollingDischargePlanScheduleStore(_ inner: MemoryRollingDischargePlanScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingDischargePlanScheduleStore {
        return CachedRollingDischargePlanScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling discharge plan schedules. Empty fields match all.
    final class RollingDischargePlanScheduleQuery {
        var category: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingDischargePlanSchedule) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingDischargePlanSchedule]) -> [RollingDischargePlanSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingDischargePlanSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingDischargePlanSchedules(_ store: any RollingDischargePlanScheduleStore, query: RollingDischargePlanScheduleQuery) -> [RollingDischargePlanSchedule] {
        return query.apply(store.list())
    }
}
