import AcmePlatform
import Foundation

extension Labs {
    /// Keeps regional result schedules by code.
    protocol RegionalResultScheduleStore {
        func find(_ code: String) -> RegionalResultSchedule?
        func save(_ item: RegionalResultSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalResultSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalResultScheduleStore: RegionalResultScheduleStore {
        var items: [String: RegionalResultSchedule]
        var order: [String]

        init(items: [String: RegionalResultSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalResultSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalResultSchedule) {
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

        func list() -> [RegionalResultSchedule] {
            var out: [RegionalResultSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalResultScheduleStore() -> any RegionalResultScheduleStore {
        return MemoryRegionalResultScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalResultScheduleStore: RegionalResultScheduleStore {
        var inner: MemoryRegionalResultScheduleStore
        var cache: TTLCache<RegionalResultSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalResultScheduleStore, cache: TTLCache<RegionalResultSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalResultSchedule? {
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

        func save(_ item: RegionalResultSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalResultSchedule] {
            return inner.list()
        }
    }

    static func newCachedRegionalResultScheduleStore(_ inner: MemoryRegionalResultScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalResultScheduleStore {
        return CachedRegionalResultScheduleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional result schedules. Empty fields match all.
    final class RegionalResultScheduleQuery {
        var name: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minLimit: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalResultSchedule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalResultSchedule]) -> [RegionalResultSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalResultSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalResultSchedules(_ store: any RegionalResultScheduleStore, query: RegionalResultScheduleQuery) -> [RegionalResultSchedule] {
        return query.apply(store.list())
    }
}
