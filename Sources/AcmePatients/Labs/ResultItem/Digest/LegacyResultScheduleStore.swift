import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy result schedules by code.
    protocol LegacyResultScheduleStore {
        func find(_ code: String) -> LegacyResultSchedule?
        func save(_ item: LegacyResultSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyResultSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyResultScheduleStore: LegacyResultScheduleStore {
        var items: [String: LegacyResultSchedule]
        var order: [String]

        init(items: [String: LegacyResultSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyResultSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyResultSchedule) {
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

        func list() -> [LegacyResultSchedule] {
            var out: [LegacyResultSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyResultScheduleStore() -> any LegacyResultScheduleStore {
        return MemoryLegacyResultScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyResultScheduleStore: LegacyResultScheduleStore {
        var inner: MemoryLegacyResultScheduleStore
        var cache: TTLCache<LegacyResultSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyResultScheduleStore, cache: TTLCache<LegacyResultSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyResultSchedule? {
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

        func save(_ item: LegacyResultSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyResultSchedule] {
            return inner.list()
        }
    }

    static func newCachedLegacyResultScheduleStore(_ inner: MemoryLegacyResultScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyResultScheduleStore {
        return CachedLegacyResultScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy result schedules. Empty fields match all.
    final class LegacyResultScheduleQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyResultSchedule) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyResultSchedule]) -> [LegacyResultSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyResultSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyResultSchedules(_ store: any LegacyResultScheduleStore, query: LegacyResultScheduleQuery) -> [LegacyResultSchedule] {
        return query.apply(store.list())
    }
}
