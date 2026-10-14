import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert schedules by code.
    protocol AlertScheduleStore {
        func find(_ code: String) -> AlertSchedule?
        func save(_ item: AlertSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [AlertSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertScheduleStore: AlertScheduleStore {
        var items: [String: AlertSchedule]
        var order: [String]

        init(items: [String: AlertSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertSchedule) {
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

        func list() -> [AlertSchedule] {
            var out: [AlertSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertScheduleStore() -> any AlertScheduleStore {
        return MemoryAlertScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertScheduleStore: AlertScheduleStore {
        var inner: MemoryAlertScheduleStore
        var cache: TTLCache<AlertSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertScheduleStore, cache: TTLCache<AlertSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertSchedule? {
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

        func save(_ item: AlertSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertSchedule] {
            return inner.list()
        }
    }

    static func newCachedAlertScheduleStore(_ inner: MemoryAlertScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertScheduleStore {
        return CachedAlertScheduleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert schedules. Empty fields match all.
    final class AlertScheduleQuery {
        var facility: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertSchedule) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertSchedule]) -> [AlertSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertSchedules(_ store: any AlertScheduleStore, query: AlertScheduleQuery) -> [AlertSchedule] {
        return query.apply(store.list())
    }
}
