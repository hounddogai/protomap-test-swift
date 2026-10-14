import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps care protocol schedules by code.
    protocol CareProtocolScheduleStore {
        func find(_ code: String) -> CareProtocolSchedule?
        func save(_ item: CareProtocolSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolScheduleStore: CareProtocolScheduleStore {
        var items: [String: CareProtocolSchedule]
        var order: [String]

        init(items: [String: CareProtocolSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolSchedule) {
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

        func list() -> [CareProtocolSchedule] {
            var out: [CareProtocolSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolScheduleStore() -> any CareProtocolScheduleStore {
        return MemoryCareProtocolScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolScheduleStore: CareProtocolScheduleStore {
        var inner: MemoryCareProtocolScheduleStore
        var cache: TTLCache<CareProtocolSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolScheduleStore, cache: TTLCache<CareProtocolSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolSchedule? {
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

        func save(_ item: CareProtocolSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolSchedule] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolScheduleStore(_ inner: MemoryCareProtocolScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolScheduleStore {
        return CachedCareProtocolScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol schedules. Empty fields match all.
    final class CareProtocolScheduleQuery {
        var locale: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolSchedule) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolSchedule]) -> [CareProtocolSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolSchedules(_ store: any CareProtocolScheduleStore, query: CareProtocolScheduleQuery) -> [CareProtocolSchedule] {
        return query.apply(store.list())
    }
}
