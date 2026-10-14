import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps cleaning schedules by code.
    protocol CleaningScheduleStore {
        func find(_ code: String) -> CleaningSchedule?
        func save(_ item: CleaningSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [CleaningSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCleaningScheduleStore: CleaningScheduleStore {
        var items: [String: CleaningSchedule]
        var order: [String]

        init(items: [String: CleaningSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CleaningSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CleaningSchedule) {
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

        func list() -> [CleaningSchedule] {
            var out: [CleaningSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCleaningScheduleStore() -> any CleaningScheduleStore {
        return MemoryCleaningScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCleaningScheduleStore: CleaningScheduleStore {
        var inner: MemoryCleaningScheduleStore
        var cache: TTLCache<CleaningSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryCleaningScheduleStore, cache: TTLCache<CleaningSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CleaningSchedule? {
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

        func save(_ item: CleaningSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CleaningSchedule] {
            return inner.list()
        }
    }

    static func newCachedCleaningScheduleStore(_ inner: MemoryCleaningScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CleaningScheduleStore {
        return CachedCleaningScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects cleaning schedules. Empty fields match all.
    final class CleaningScheduleQuery {
        var name: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CleaningSchedule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CleaningSchedule]) -> [CleaningSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CleaningSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCleaningSchedules(_ store: any CleaningScheduleStore, query: CleaningScheduleQuery) -> [CleaningSchedule] {
        return query.apply(store.list())
    }
}
