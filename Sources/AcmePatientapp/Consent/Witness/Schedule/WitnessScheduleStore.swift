import AcmePlatform
import Foundation

extension Consent {
    /// Keeps witness schedules by code.
    protocol WitnessScheduleStore {
        func find(_ code: String) -> WitnessSchedule?
        func save(_ item: WitnessSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [WitnessSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWitnessScheduleStore: WitnessScheduleStore {
        var items: [String: WitnessSchedule]
        var order: [String]

        init(items: [String: WitnessSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WitnessSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WitnessSchedule) {
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

        func list() -> [WitnessSchedule] {
            var out: [WitnessSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWitnessScheduleStore() -> any WitnessScheduleStore {
        return MemoryWitnessScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWitnessScheduleStore: WitnessScheduleStore {
        var inner: MemoryWitnessScheduleStore
        var cache: TTLCache<WitnessSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryWitnessScheduleStore, cache: TTLCache<WitnessSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WitnessSchedule? {
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

        func save(_ item: WitnessSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WitnessSchedule] {
            return inner.list()
        }
    }

    static func newCachedWitnessScheduleStore(_ inner: MemoryWitnessScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WitnessScheduleStore {
        return CachedWitnessScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects witness schedules. Empty fields match all.
    final class WitnessScheduleQuery {
        var locale: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WitnessSchedule) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WitnessSchedule]) -> [WitnessSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WitnessSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWitnessSchedules(_ store: any WitnessScheduleStore, query: WitnessScheduleQuery) -> [WitnessSchedule] {
        return query.apply(store.list())
    }
}
