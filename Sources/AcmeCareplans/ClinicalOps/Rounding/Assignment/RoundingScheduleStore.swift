import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding schedules by code.
    protocol RoundingScheduleStore {
        func find(_ code: String) -> RoundingSchedule?
        func save(_ item: RoundingSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingScheduleStore: RoundingScheduleStore {
        var items: [String: RoundingSchedule]
        var order: [String]

        init(items: [String: RoundingSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingSchedule) {
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

        func list() -> [RoundingSchedule] {
            var out: [RoundingSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingScheduleStore() -> any RoundingScheduleStore {
        return MemoryRoundingScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingScheduleStore: RoundingScheduleStore {
        var inner: MemoryRoundingScheduleStore
        var cache: TTLCache<RoundingSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingScheduleStore, cache: TTLCache<RoundingSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingSchedule? {
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

        func save(_ item: RoundingSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingSchedule] {
            return inner.list()
        }
    }

    static func newCachedRoundingScheduleStore(_ inner: MemoryRoundingScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingScheduleStore {
        return CachedRoundingScheduleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding schedules. Empty fields match all.
    final class RoundingScheduleQuery {
        var title: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RoundingSchedule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RoundingSchedule]) -> [RoundingSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingSchedules(_ store: any RoundingScheduleStore, query: RoundingScheduleQuery) -> [RoundingSchedule] {
        return query.apply(store.list())
    }
}
