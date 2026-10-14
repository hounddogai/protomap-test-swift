import AcmePlatform
import Foundation

extension Labs {
    /// Keeps primary reference range schedules by code.
    protocol PrimaryReferenceRangeScheduleStore {
        func find(_ code: String) -> PrimaryReferenceRangeSchedule?
        func save(_ item: PrimaryReferenceRangeSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryReferenceRangeSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryReferenceRangeScheduleStore: PrimaryReferenceRangeScheduleStore {
        var items: [String: PrimaryReferenceRangeSchedule]
        var order: [String]

        init(items: [String: PrimaryReferenceRangeSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryReferenceRangeSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryReferenceRangeSchedule) {
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

        func list() -> [PrimaryReferenceRangeSchedule] {
            var out: [PrimaryReferenceRangeSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryReferenceRangeScheduleStore() -> any PrimaryReferenceRangeScheduleStore {
        return MemoryPrimaryReferenceRangeScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryReferenceRangeScheduleStore: PrimaryReferenceRangeScheduleStore {
        var inner: MemoryPrimaryReferenceRangeScheduleStore
        var cache: TTLCache<PrimaryReferenceRangeSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryReferenceRangeScheduleStore, cache: TTLCache<PrimaryReferenceRangeSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryReferenceRangeSchedule? {
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

        func save(_ item: PrimaryReferenceRangeSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryReferenceRangeSchedule] {
            return inner.list()
        }
    }

    static func newCachedPrimaryReferenceRangeScheduleStore(_ inner: MemoryPrimaryReferenceRangeScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryReferenceRangeScheduleStore {
        return CachedPrimaryReferenceRangeScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary reference range schedules. Empty fields match all.
    final class PrimaryReferenceRangeScheduleQuery {
        var channel: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minScore: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryReferenceRangeSchedule) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryReferenceRangeSchedule]) -> [PrimaryReferenceRangeSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryReferenceRangeSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryReferenceRangeSchedules(_ store: any PrimaryReferenceRangeScheduleStore, query: PrimaryReferenceRangeScheduleQuery) -> [PrimaryReferenceRangeSchedule] {
        return query.apply(store.list())
    }
}
