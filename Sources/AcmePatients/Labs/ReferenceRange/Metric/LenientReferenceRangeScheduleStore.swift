import AcmePlatform
import Foundation

extension Labs {
    /// Keeps lenient reference range schedules by code.
    protocol LenientReferenceRangeScheduleStore {
        func find(_ code: String) -> LenientReferenceRangeSchedule?
        func save(_ item: LenientReferenceRangeSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [LenientReferenceRangeSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientReferenceRangeScheduleStore: LenientReferenceRangeScheduleStore {
        var items: [String: LenientReferenceRangeSchedule]
        var order: [String]

        init(items: [String: LenientReferenceRangeSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientReferenceRangeSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientReferenceRangeSchedule) {
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

        func list() -> [LenientReferenceRangeSchedule] {
            var out: [LenientReferenceRangeSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientReferenceRangeScheduleStore() -> any LenientReferenceRangeScheduleStore {
        return MemoryLenientReferenceRangeScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientReferenceRangeScheduleStore: LenientReferenceRangeScheduleStore {
        var inner: MemoryLenientReferenceRangeScheduleStore
        var cache: TTLCache<LenientReferenceRangeSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientReferenceRangeScheduleStore, cache: TTLCache<LenientReferenceRangeSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientReferenceRangeSchedule? {
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

        func save(_ item: LenientReferenceRangeSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientReferenceRangeSchedule] {
            return inner.list()
        }
    }

    static func newCachedLenientReferenceRangeScheduleStore(_ inner: MemoryLenientReferenceRangeScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientReferenceRangeScheduleStore {
        return CachedLenientReferenceRangeScheduleStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient reference range schedules. Empty fields match all.
    final class LenientReferenceRangeScheduleQuery {
        var locale: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientReferenceRangeSchedule) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientReferenceRangeSchedule]) -> [LenientReferenceRangeSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientReferenceRangeSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientReferenceRangeSchedules(_ store: any LenientReferenceRangeScheduleStore, query: LenientReferenceRangeScheduleQuery) -> [LenientReferenceRangeSchedule] {
        return query.apply(store.list())
    }
}
