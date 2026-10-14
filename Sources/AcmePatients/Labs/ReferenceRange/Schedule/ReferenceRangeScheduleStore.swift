import AcmePlatform
import Foundation

extension Labs {
    /// Keeps reference range schedules by code.
    protocol ReferenceRangeScheduleStore {
        func find(_ code: String) -> ReferenceRangeSchedule?
        func save(_ item: ReferenceRangeSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [ReferenceRangeSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferenceRangeScheduleStore: ReferenceRangeScheduleStore {
        var items: [String: ReferenceRangeSchedule]
        var order: [String]

        init(items: [String: ReferenceRangeSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferenceRangeSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferenceRangeSchedule) {
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

        func list() -> [ReferenceRangeSchedule] {
            var out: [ReferenceRangeSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferenceRangeScheduleStore() -> any ReferenceRangeScheduleStore {
        return MemoryReferenceRangeScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferenceRangeScheduleStore: ReferenceRangeScheduleStore {
        var inner: MemoryReferenceRangeScheduleStore
        var cache: TTLCache<ReferenceRangeSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferenceRangeScheduleStore, cache: TTLCache<ReferenceRangeSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferenceRangeSchedule? {
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

        func save(_ item: ReferenceRangeSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferenceRangeSchedule] {
            return inner.list()
        }
    }

    static func newCachedReferenceRangeScheduleStore(_ inner: MemoryReferenceRangeScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferenceRangeScheduleStore {
        return CachedReferenceRangeScheduleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects reference range schedules. Empty fields match all.
    final class ReferenceRangeScheduleQuery {
        var channel: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minBudget: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferenceRangeSchedule) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferenceRangeSchedule]) -> [ReferenceRangeSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferenceRangeSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferenceRangeSchedules(_ store: any ReferenceRangeScheduleStore, query: ReferenceRangeScheduleQuery) -> [ReferenceRangeSchedule] {
        return query.apply(store.list())
    }
}
