import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up schedules by code.
    protocol FollowUpScheduleStore {
        func find(_ code: String) -> FollowUpSchedule?
        func save(_ item: FollowUpSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpScheduleStore: FollowUpScheduleStore {
        var items: [String: FollowUpSchedule]
        var order: [String]

        init(items: [String: FollowUpSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpSchedule) {
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

        func list() -> [FollowUpSchedule] {
            var out: [FollowUpSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpScheduleStore() -> any FollowUpScheduleStore {
        return MemoryFollowUpScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpScheduleStore: FollowUpScheduleStore {
        var inner: MemoryFollowUpScheduleStore
        var cache: TTLCache<FollowUpSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpScheduleStore, cache: TTLCache<FollowUpSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpSchedule? {
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

        func save(_ item: FollowUpSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpSchedule] {
            return inner.list()
        }
    }

    static func newCachedFollowUpScheduleStore(_ inner: MemoryFollowUpScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpScheduleStore {
        return CachedFollowUpScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up schedules. Empty fields match all.
    final class FollowUpScheduleQuery {
        var label: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minAmount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpSchedule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpSchedule]) -> [FollowUpSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpSchedules(_ store: any FollowUpScheduleStore, query: FollowUpScheduleQuery) -> [FollowUpSchedule] {
        return query.apply(store.list())
    }
}
