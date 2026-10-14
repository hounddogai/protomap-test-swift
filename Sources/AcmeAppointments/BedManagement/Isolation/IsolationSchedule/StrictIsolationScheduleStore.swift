import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps strict isolation schedules by code.
    protocol StrictIsolationScheduleStore {
        func find(_ code: String) -> StrictIsolationSchedule?
        func save(_ item: StrictIsolationSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [StrictIsolationSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictIsolationScheduleStore: StrictIsolationScheduleStore {
        var items: [String: StrictIsolationSchedule]
        var order: [String]

        init(items: [String: StrictIsolationSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictIsolationSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictIsolationSchedule) {
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

        func list() -> [StrictIsolationSchedule] {
            var out: [StrictIsolationSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictIsolationScheduleStore() -> any StrictIsolationScheduleStore {
        return MemoryStrictIsolationScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictIsolationScheduleStore: StrictIsolationScheduleStore {
        var inner: MemoryStrictIsolationScheduleStore
        var cache: TTLCache<StrictIsolationSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictIsolationScheduleStore, cache: TTLCache<StrictIsolationSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictIsolationSchedule? {
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

        func save(_ item: StrictIsolationSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictIsolationSchedule] {
            return inner.list()
        }
    }

    static func newCachedStrictIsolationScheduleStore(_ inner: MemoryStrictIsolationScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictIsolationScheduleStore {
        return CachedStrictIsolationScheduleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict isolation schedules. Empty fields match all.
    final class StrictIsolationScheduleQuery {
        var unit: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minScore: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictIsolationSchedule) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictIsolationSchedule]) -> [StrictIsolationSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictIsolationSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictIsolationSchedules(_ store: any StrictIsolationScheduleStore, query: StrictIsolationScheduleQuery) -> [StrictIsolationSchedule] {
        return query.apply(store.list())
    }
}
