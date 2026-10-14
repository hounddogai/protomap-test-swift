import AcmePlatform
import Foundation

extension Labs {
    /// Keeps specimen schedules by code.
    protocol SpecimenScheduleStore {
        func find(_ code: String) -> SpecimenSchedule?
        func save(_ item: SpecimenSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [SpecimenSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySpecimenScheduleStore: SpecimenScheduleStore {
        var items: [String: SpecimenSchedule]
        var order: [String]

        init(items: [String: SpecimenSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SpecimenSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SpecimenSchedule) {
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

        func list() -> [SpecimenSchedule] {
            var out: [SpecimenSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySpecimenScheduleStore() -> any SpecimenScheduleStore {
        return MemorySpecimenScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSpecimenScheduleStore: SpecimenScheduleStore {
        var inner: MemorySpecimenScheduleStore
        var cache: TTLCache<SpecimenSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemorySpecimenScheduleStore, cache: TTLCache<SpecimenSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SpecimenSchedule? {
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

        func save(_ item: SpecimenSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SpecimenSchedule] {
            return inner.list()
        }
    }

    static func newCachedSpecimenScheduleStore(_ inner: MemorySpecimenScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SpecimenScheduleStore {
        return CachedSpecimenScheduleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects specimen schedules. Empty fields match all.
    final class SpecimenScheduleQuery {
        var title: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minBudget: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SpecimenSchedule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [SpecimenSchedule]) -> [SpecimenSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SpecimenSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSpecimenSchedules(_ store: any SpecimenScheduleStore, query: SpecimenScheduleQuery) -> [SpecimenSchedule] {
        return query.apply(store.list())
    }
}
