import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps scheduled care protocol schedules by code.
    protocol ScheduledCareProtocolScheduleStore {
        func find(_ code: String) -> ScheduledCareProtocolSchedule?
        func save(_ item: ScheduledCareProtocolSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledCareProtocolSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledCareProtocolScheduleStore: ScheduledCareProtocolScheduleStore {
        var items: [String: ScheduledCareProtocolSchedule]
        var order: [String]

        init(items: [String: ScheduledCareProtocolSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledCareProtocolSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledCareProtocolSchedule) {
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

        func list() -> [ScheduledCareProtocolSchedule] {
            var out: [ScheduledCareProtocolSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledCareProtocolScheduleStore() -> any ScheduledCareProtocolScheduleStore {
        return MemoryScheduledCareProtocolScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledCareProtocolScheduleStore: ScheduledCareProtocolScheduleStore {
        var inner: MemoryScheduledCareProtocolScheduleStore
        var cache: TTLCache<ScheduledCareProtocolSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledCareProtocolScheduleStore, cache: TTLCache<ScheduledCareProtocolSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledCareProtocolSchedule? {
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

        func save(_ item: ScheduledCareProtocolSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledCareProtocolSchedule] {
            return inner.list()
        }
    }

    static func newCachedScheduledCareProtocolScheduleStore(_ inner: MemoryScheduledCareProtocolScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledCareProtocolScheduleStore {
        return CachedScheduledCareProtocolScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled care protocol schedules. Empty fields match all.
    final class ScheduledCareProtocolScheduleQuery {
        var name: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minRatio: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledCareProtocolSchedule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledCareProtocolSchedule]) -> [ScheduledCareProtocolSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledCareProtocolSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledCareProtocolSchedules(_ store: any ScheduledCareProtocolScheduleStore, query: ScheduledCareProtocolScheduleQuery) -> [ScheduledCareProtocolSchedule] {
        return query.apply(store.list())
    }
}
