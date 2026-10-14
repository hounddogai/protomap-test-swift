import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps legacy bed board schedules by code.
    protocol LegacyBedBoardScheduleStore {
        func find(_ code: String) -> LegacyBedBoardSchedule?
        func save(_ item: LegacyBedBoardSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyBedBoardSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyBedBoardScheduleStore: LegacyBedBoardScheduleStore {
        var items: [String: LegacyBedBoardSchedule]
        var order: [String]

        init(items: [String: LegacyBedBoardSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyBedBoardSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyBedBoardSchedule) {
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

        func list() -> [LegacyBedBoardSchedule] {
            var out: [LegacyBedBoardSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyBedBoardScheduleStore() -> any LegacyBedBoardScheduleStore {
        return MemoryLegacyBedBoardScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyBedBoardScheduleStore: LegacyBedBoardScheduleStore {
        var inner: MemoryLegacyBedBoardScheduleStore
        var cache: TTLCache<LegacyBedBoardSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyBedBoardScheduleStore, cache: TTLCache<LegacyBedBoardSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyBedBoardSchedule? {
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

        func save(_ item: LegacyBedBoardSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyBedBoardSchedule] {
            return inner.list()
        }
    }

    static func newCachedLegacyBedBoardScheduleStore(_ inner: MemoryLegacyBedBoardScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyBedBoardScheduleStore {
        return CachedLegacyBedBoardScheduleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy bed board schedules. Empty fields match all.
    final class LegacyBedBoardScheduleQuery {
        var country: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minPriority: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyBedBoardSchedule) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyBedBoardSchedule]) -> [LegacyBedBoardSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyBedBoardSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyBedBoardSchedules(_ store: any LegacyBedBoardScheduleStore, query: LegacyBedBoardScheduleQuery) -> [LegacyBedBoardSchedule] {
        return query.apply(store.list())
    }
}
