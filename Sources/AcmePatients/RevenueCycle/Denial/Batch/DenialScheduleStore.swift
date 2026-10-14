import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial schedules by code.
    protocol DenialScheduleStore {
        func find(_ code: String) -> DenialSchedule?
        func save(_ item: DenialSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [DenialSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialScheduleStore: DenialScheduleStore {
        var items: [String: DenialSchedule]
        var order: [String]

        init(items: [String: DenialSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialSchedule) {
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

        func list() -> [DenialSchedule] {
            var out: [DenialSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialScheduleStore() -> any DenialScheduleStore {
        return MemoryDenialScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialScheduleStore: DenialScheduleStore {
        var inner: MemoryDenialScheduleStore
        var cache: TTLCache<DenialSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialScheduleStore, cache: TTLCache<DenialSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialSchedule? {
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

        func save(_ item: DenialSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialSchedule] {
            return inner.list()
        }
    }

    static func newCachedDenialScheduleStore(_ inner: MemoryDenialScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialScheduleStore {
        return CachedDenialScheduleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial schedules. Empty fields match all.
    final class DenialScheduleQuery {
        var ward: String
        var minMinimum: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMinimum: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMinimum = minMinimum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialSchedule) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.minimum < minMinimum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DenialSchedule]) -> [DenialSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialSchedules(_ store: any DenialScheduleStore, query: DenialScheduleQuery) -> [DenialSchedule] {
        return query.apply(store.list())
    }
}
