import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps adaptive study schedules by code.
    protocol AdaptiveStudyScheduleStore {
        func find(_ code: String) -> AdaptiveStudySchedule?
        func save(_ item: AdaptiveStudySchedule)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveStudySchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveStudyScheduleStore: AdaptiveStudyScheduleStore {
        var items: [String: AdaptiveStudySchedule]
        var order: [String]

        init(items: [String: AdaptiveStudySchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveStudySchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveStudySchedule) {
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

        func list() -> [AdaptiveStudySchedule] {
            var out: [AdaptiveStudySchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveStudyScheduleStore() -> any AdaptiveStudyScheduleStore {
        return MemoryAdaptiveStudyScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveStudyScheduleStore: AdaptiveStudyScheduleStore {
        var inner: MemoryAdaptiveStudyScheduleStore
        var cache: TTLCache<AdaptiveStudySchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveStudyScheduleStore, cache: TTLCache<AdaptiveStudySchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveStudySchedule? {
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

        func save(_ item: AdaptiveStudySchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveStudySchedule] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveStudyScheduleStore(_ inner: MemoryAdaptiveStudyScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveStudyScheduleStore {
        return CachedAdaptiveStudyScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive study schedules. Empty fields match all.
    final class AdaptiveStudyScheduleQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveStudySchedule) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveStudySchedule]) -> [AdaptiveStudySchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveStudySchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveStudySchedules(_ store: any AdaptiveStudyScheduleStore, query: AdaptiveStudyScheduleQuery) -> [AdaptiveStudySchedule] {
        return query.apply(store.list())
    }
}
