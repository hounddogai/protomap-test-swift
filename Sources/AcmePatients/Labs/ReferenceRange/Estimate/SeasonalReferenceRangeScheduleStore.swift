import AcmePlatform
import Foundation

extension Labs {
    /// Keeps seasonal reference range schedules by code.
    protocol SeasonalReferenceRangeScheduleStore {
        func find(_ code: String) -> SeasonalReferenceRangeSchedule?
        func save(_ item: SeasonalReferenceRangeSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [SeasonalReferenceRangeSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemorySeasonalReferenceRangeScheduleStore: SeasonalReferenceRangeScheduleStore {
        var items: [String: SeasonalReferenceRangeSchedule]
        var order: [String]

        init(items: [String: SeasonalReferenceRangeSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> SeasonalReferenceRangeSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: SeasonalReferenceRangeSchedule) {
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

        func list() -> [SeasonalReferenceRangeSchedule] {
            var out: [SeasonalReferenceRangeSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemorySeasonalReferenceRangeScheduleStore() -> any SeasonalReferenceRangeScheduleStore {
        return MemorySeasonalReferenceRangeScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedSeasonalReferenceRangeScheduleStore: SeasonalReferenceRangeScheduleStore {
        var inner: MemorySeasonalReferenceRangeScheduleStore
        var cache: TTLCache<SeasonalReferenceRangeSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemorySeasonalReferenceRangeScheduleStore, cache: TTLCache<SeasonalReferenceRangeSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> SeasonalReferenceRangeSchedule? {
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

        func save(_ item: SeasonalReferenceRangeSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [SeasonalReferenceRangeSchedule] {
            return inner.list()
        }
    }

    static func newCachedSeasonalReferenceRangeScheduleStore(_ inner: MemorySeasonalReferenceRangeScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any SeasonalReferenceRangeScheduleStore {
        return CachedSeasonalReferenceRangeScheduleStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects seasonal reference range schedules. Empty fields match all.
    final class SeasonalReferenceRangeScheduleQuery {
        var title: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: SeasonalReferenceRangeSchedule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [SeasonalReferenceRangeSchedule]) -> [SeasonalReferenceRangeSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: SeasonalReferenceRangeSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findSeasonalReferenceRangeSchedules(_ store: any SeasonalReferenceRangeScheduleStore, query: SeasonalReferenceRangeScheduleQuery) -> [SeasonalReferenceRangeSchedule] {
        return query.apply(store.list())
    }
}
