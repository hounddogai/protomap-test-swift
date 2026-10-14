import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps primary isolation schedules by code.
    protocol PrimaryIsolationScheduleStore {
        func find(_ code: String) -> PrimaryIsolationSchedule?
        func save(_ item: PrimaryIsolationSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryIsolationSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryIsolationScheduleStore: PrimaryIsolationScheduleStore {
        var items: [String: PrimaryIsolationSchedule]
        var order: [String]

        init(items: [String: PrimaryIsolationSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryIsolationSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryIsolationSchedule) {
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

        func list() -> [PrimaryIsolationSchedule] {
            var out: [PrimaryIsolationSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryIsolationScheduleStore() -> any PrimaryIsolationScheduleStore {
        return MemoryPrimaryIsolationScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryIsolationScheduleStore: PrimaryIsolationScheduleStore {
        var inner: MemoryPrimaryIsolationScheduleStore
        var cache: TTLCache<PrimaryIsolationSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryIsolationScheduleStore, cache: TTLCache<PrimaryIsolationSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryIsolationSchedule? {
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

        func save(_ item: PrimaryIsolationSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryIsolationSchedule] {
            return inner.list()
        }
    }

    static func newCachedPrimaryIsolationScheduleStore(_ inner: MemoryPrimaryIsolationScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryIsolationScheduleStore {
        return CachedPrimaryIsolationScheduleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary isolation schedules. Empty fields match all.
    final class PrimaryIsolationScheduleQuery {
        var country: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryIsolationSchedule) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryIsolationSchedule]) -> [PrimaryIsolationSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryIsolationSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryIsolationSchedules(_ store: any PrimaryIsolationScheduleStore, query: PrimaryIsolationScheduleQuery) -> [PrimaryIsolationSchedule] {
        return query.apply(store.list())
    }
}
