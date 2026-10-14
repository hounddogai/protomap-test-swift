import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps outreach schedules by code.
    protocol OutreachScheduleStore {
        func find(_ code: String) -> OutreachSchedule?
        func save(_ item: OutreachSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [OutreachSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOutreachScheduleStore: OutreachScheduleStore {
        var items: [String: OutreachSchedule]
        var order: [String]

        init(items: [String: OutreachSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OutreachSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OutreachSchedule) {
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

        func list() -> [OutreachSchedule] {
            var out: [OutreachSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOutreachScheduleStore() -> any OutreachScheduleStore {
        return MemoryOutreachScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOutreachScheduleStore: OutreachScheduleStore {
        var inner: MemoryOutreachScheduleStore
        var cache: TTLCache<OutreachSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryOutreachScheduleStore, cache: TTLCache<OutreachSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OutreachSchedule? {
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

        func save(_ item: OutreachSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OutreachSchedule] {
            return inner.list()
        }
    }

    static func newCachedOutreachScheduleStore(_ inner: MemoryOutreachScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OutreachScheduleStore {
        return CachedOutreachScheduleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects outreach schedules. Empty fields match all.
    final class OutreachScheduleQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OutreachSchedule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [OutreachSchedule]) -> [OutreachSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OutreachSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOutreachSchedules(_ store: any OutreachScheduleStore, query: OutreachScheduleQuery) -> [OutreachSchedule] {
        return query.apply(store.list())
    }
}
