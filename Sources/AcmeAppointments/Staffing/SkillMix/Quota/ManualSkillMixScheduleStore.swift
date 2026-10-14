import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps manual skill mix schedules by code.
    protocol ManualSkillMixScheduleStore {
        func find(_ code: String) -> ManualSkillMixSchedule?
        func save(_ item: ManualSkillMixSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [ManualSkillMixSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualSkillMixScheduleStore: ManualSkillMixScheduleStore {
        var items: [String: ManualSkillMixSchedule]
        var order: [String]

        init(items: [String: ManualSkillMixSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualSkillMixSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualSkillMixSchedule) {
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

        func list() -> [ManualSkillMixSchedule] {
            var out: [ManualSkillMixSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualSkillMixScheduleStore() -> any ManualSkillMixScheduleStore {
        return MemoryManualSkillMixScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualSkillMixScheduleStore: ManualSkillMixScheduleStore {
        var inner: MemoryManualSkillMixScheduleStore
        var cache: TTLCache<ManualSkillMixSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualSkillMixScheduleStore, cache: TTLCache<ManualSkillMixSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualSkillMixSchedule? {
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

        func save(_ item: ManualSkillMixSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualSkillMixSchedule] {
            return inner.list()
        }
    }

    static func newCachedManualSkillMixScheduleStore(_ inner: MemoryManualSkillMixScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualSkillMixScheduleStore {
        return CachedManualSkillMixScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual skill mix schedules. Empty fields match all.
    final class ManualSkillMixScheduleQuery {
        var label: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualSkillMixSchedule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualSkillMixSchedule]) -> [ManualSkillMixSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualSkillMixSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualSkillMixSchedules(_ store: any ManualSkillMixScheduleStore, query: ManualSkillMixScheduleQuery) -> [ManualSkillMixSchedule] {
        return query.apply(store.list())
    }
}
