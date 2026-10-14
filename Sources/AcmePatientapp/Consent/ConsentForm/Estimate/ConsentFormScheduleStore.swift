import AcmePlatform
import Foundation

extension Consent {
    /// Keeps consent form schedules by code.
    protocol ConsentFormScheduleStore {
        func find(_ code: String) -> ConsentFormSchedule?
        func save(_ item: ConsentFormSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [ConsentFormSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryConsentFormScheduleStore: ConsentFormScheduleStore {
        var items: [String: ConsentFormSchedule]
        var order: [String]

        init(items: [String: ConsentFormSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ConsentFormSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ConsentFormSchedule) {
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

        func list() -> [ConsentFormSchedule] {
            var out: [ConsentFormSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryConsentFormScheduleStore() -> any ConsentFormScheduleStore {
        return MemoryConsentFormScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedConsentFormScheduleStore: ConsentFormScheduleStore {
        var inner: MemoryConsentFormScheduleStore
        var cache: TTLCache<ConsentFormSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryConsentFormScheduleStore, cache: TTLCache<ConsentFormSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ConsentFormSchedule? {
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

        func save(_ item: ConsentFormSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ConsentFormSchedule] {
            return inner.list()
        }
    }

    static func newCachedConsentFormScheduleStore(_ inner: MemoryConsentFormScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ConsentFormScheduleStore {
        return CachedConsentFormScheduleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects consent form schedules. Empty fields match all.
    final class ConsentFormScheduleQuery {
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

        func matches(_ item: ConsentFormSchedule) -> Bool {
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

        func apply(_ items: [ConsentFormSchedule]) -> [ConsentFormSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ConsentFormSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findConsentFormSchedules(_ store: any ConsentFormScheduleStore, query: ConsentFormScheduleQuery) -> [ConsentFormSchedule] {
        return query.apply(store.list())
    }
}
