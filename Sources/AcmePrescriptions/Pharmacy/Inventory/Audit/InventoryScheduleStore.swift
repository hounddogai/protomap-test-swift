import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory schedules by code.
    protocol InventoryScheduleStore {
        func find(_ code: String) -> InventorySchedule?
        func save(_ item: InventorySchedule)
        func remove(_ code: String) -> Bool
        func list() -> [InventorySchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryScheduleStore: InventoryScheduleStore {
        var items: [String: InventorySchedule]
        var order: [String]

        init(items: [String: InventorySchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventorySchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventorySchedule) {
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

        func list() -> [InventorySchedule] {
            var out: [InventorySchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryScheduleStore() -> any InventoryScheduleStore {
        return MemoryInventoryScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryScheduleStore: InventoryScheduleStore {
        var inner: MemoryInventoryScheduleStore
        var cache: TTLCache<InventorySchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryScheduleStore, cache: TTLCache<InventorySchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventorySchedule? {
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

        func save(_ item: InventorySchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventorySchedule] {
            return inner.list()
        }
    }

    static func newCachedInventoryScheduleStore(_ inner: MemoryInventoryScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryScheduleStore {
        return CachedInventoryScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory schedules. Empty fields match all.
    final class InventoryScheduleQuery {
        var locale: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventorySchedule) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [InventorySchedule]) -> [InventorySchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventorySchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventorySchedules(_ store: any InventoryScheduleStore, query: InventoryScheduleQuery) -> [InventorySchedule] {
        return query.apply(store.list())
    }
}
