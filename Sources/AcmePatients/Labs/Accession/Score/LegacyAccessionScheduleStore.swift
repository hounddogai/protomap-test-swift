import AcmePlatform
import Foundation

extension Labs {
    /// Keeps legacy accession schedules by code.
    protocol LegacyAccessionScheduleStore {
        func find(_ code: String) -> LegacyAccessionSchedule?
        func save(_ item: LegacyAccessionSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyAccessionSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyAccessionScheduleStore: LegacyAccessionScheduleStore {
        var items: [String: LegacyAccessionSchedule]
        var order: [String]

        init(items: [String: LegacyAccessionSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyAccessionSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyAccessionSchedule) {
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

        func list() -> [LegacyAccessionSchedule] {
            var out: [LegacyAccessionSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyAccessionScheduleStore() -> any LegacyAccessionScheduleStore {
        return MemoryLegacyAccessionScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyAccessionScheduleStore: LegacyAccessionScheduleStore {
        var inner: MemoryLegacyAccessionScheduleStore
        var cache: TTLCache<LegacyAccessionSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyAccessionScheduleStore, cache: TTLCache<LegacyAccessionSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyAccessionSchedule? {
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

        func save(_ item: LegacyAccessionSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyAccessionSchedule] {
            return inner.list()
        }
    }

    static func newCachedLegacyAccessionScheduleStore(_ inner: MemoryLegacyAccessionScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyAccessionScheduleStore {
        return CachedLegacyAccessionScheduleStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy accession schedules. Empty fields match all.
    final class LegacyAccessionScheduleQuery {
        var label: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minVersion: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyAccessionSchedule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.version < minVersion {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyAccessionSchedule]) -> [LegacyAccessionSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyAccessionSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyAccessionSchedules(_ store: any LegacyAccessionScheduleStore, query: LegacyAccessionScheduleQuery) -> [LegacyAccessionSchedule] {
        return query.apply(store.list())
    }
}
