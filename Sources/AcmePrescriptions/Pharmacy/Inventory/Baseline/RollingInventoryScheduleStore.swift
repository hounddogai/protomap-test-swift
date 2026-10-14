import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps rolling inventory schedules by code.
    protocol RollingInventoryScheduleStore {
        func find(_ code: String) -> RollingInventorySchedule?
        func save(_ item: RollingInventorySchedule)
        func remove(_ code: String) -> Bool
        func list() -> [RollingInventorySchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingInventoryScheduleStore: RollingInventoryScheduleStore {
        var items: [String: RollingInventorySchedule]
        var order: [String]

        init(items: [String: RollingInventorySchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingInventorySchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingInventorySchedule) {
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

        func list() -> [RollingInventorySchedule] {
            var out: [RollingInventorySchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingInventoryScheduleStore() -> any RollingInventoryScheduleStore {
        return MemoryRollingInventoryScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingInventoryScheduleStore: RollingInventoryScheduleStore {
        var inner: MemoryRollingInventoryScheduleStore
        var cache: TTLCache<RollingInventorySchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingInventoryScheduleStore, cache: TTLCache<RollingInventorySchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingInventorySchedule? {
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

        func save(_ item: RollingInventorySchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingInventorySchedule] {
            return inner.list()
        }
    }

    static func newCachedRollingInventoryScheduleStore(_ inner: MemoryRollingInventoryScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingInventoryScheduleStore {
        return CachedRollingInventoryScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling inventory schedules. Empty fields match all.
    final class RollingInventoryScheduleQuery {
        var region: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minRefills: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingInventorySchedule) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingInventorySchedule]) -> [RollingInventorySchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingInventorySchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingInventorySchedules(_ store: any RollingInventoryScheduleStore, query: RollingInventoryScheduleQuery) -> [RollingInventorySchedule] {
        return query.apply(store.list())
    }
}
