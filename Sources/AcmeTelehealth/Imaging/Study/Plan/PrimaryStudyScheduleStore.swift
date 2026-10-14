import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps primary study schedules by code.
    protocol PrimaryStudyScheduleStore {
        func find(_ code: String) -> PrimaryStudySchedule?
        func save(_ item: PrimaryStudySchedule)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryStudySchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryStudyScheduleStore: PrimaryStudyScheduleStore {
        var items: [String: PrimaryStudySchedule]
        var order: [String]

        init(items: [String: PrimaryStudySchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryStudySchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryStudySchedule) {
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

        func list() -> [PrimaryStudySchedule] {
            var out: [PrimaryStudySchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryStudyScheduleStore() -> any PrimaryStudyScheduleStore {
        return MemoryPrimaryStudyScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryStudyScheduleStore: PrimaryStudyScheduleStore {
        var inner: MemoryPrimaryStudyScheduleStore
        var cache: TTLCache<PrimaryStudySchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryStudyScheduleStore, cache: TTLCache<PrimaryStudySchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryStudySchedule? {
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

        func save(_ item: PrimaryStudySchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryStudySchedule] {
            return inner.list()
        }
    }

    static func newCachedPrimaryStudyScheduleStore(_ inner: MemoryPrimaryStudyScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryStudyScheduleStore {
        return CachedPrimaryStudyScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary study schedules. Empty fields match all.
    final class PrimaryStudyScheduleQuery {
        var label: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryStudySchedule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryStudySchedule]) -> [PrimaryStudySchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryStudySchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryStudySchedules(_ store: any PrimaryStudyScheduleStore, query: PrimaryStudyScheduleQuery) -> [PrimaryStudySchedule] {
        return query.apply(store.list())
    }
}
