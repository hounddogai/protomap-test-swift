import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read schedules by code.
    protocol ReadScheduleStore {
        func find(_ code: String) -> ReadSchedule?
        func save(_ item: ReadSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [ReadSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadScheduleStore: ReadScheduleStore {
        var items: [String: ReadSchedule]
        var order: [String]

        init(items: [String: ReadSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadSchedule) {
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

        func list() -> [ReadSchedule] {
            var out: [ReadSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadScheduleStore() -> any ReadScheduleStore {
        return MemoryReadScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadScheduleStore: ReadScheduleStore {
        var inner: MemoryReadScheduleStore
        var cache: TTLCache<ReadSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadScheduleStore, cache: TTLCache<ReadSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadSchedule? {
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

        func save(_ item: ReadSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadSchedule] {
            return inner.list()
        }
    }

    static func newCachedReadScheduleStore(_ inner: MemoryReadScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadScheduleStore {
        return CachedReadScheduleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read schedules. Empty fields match all.
    final class ReadScheduleQuery {
        var facility: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadSchedule) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReadSchedule]) -> [ReadSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadSchedules(_ store: any ReadScheduleStore, query: ReadScheduleQuery) -> [ReadSchedule] {
        return query.apply(store.list())
    }
}
