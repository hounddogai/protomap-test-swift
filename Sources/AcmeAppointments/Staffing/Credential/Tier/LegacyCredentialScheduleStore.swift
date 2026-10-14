import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps legacy credential schedules by code.
    protocol LegacyCredentialScheduleStore {
        func find(_ code: String) -> LegacyCredentialSchedule?
        func save(_ item: LegacyCredentialSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyCredentialSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyCredentialScheduleStore: LegacyCredentialScheduleStore {
        var items: [String: LegacyCredentialSchedule]
        var order: [String]

        init(items: [String: LegacyCredentialSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyCredentialSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyCredentialSchedule) {
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

        func list() -> [LegacyCredentialSchedule] {
            var out: [LegacyCredentialSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyCredentialScheduleStore() -> any LegacyCredentialScheduleStore {
        return MemoryLegacyCredentialScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyCredentialScheduleStore: LegacyCredentialScheduleStore {
        var inner: MemoryLegacyCredentialScheduleStore
        var cache: TTLCache<LegacyCredentialSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyCredentialScheduleStore, cache: TTLCache<LegacyCredentialSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyCredentialSchedule? {
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

        func save(_ item: LegacyCredentialSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyCredentialSchedule] {
            return inner.list()
        }
    }

    static func newCachedLegacyCredentialScheduleStore(_ inner: MemoryLegacyCredentialScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyCredentialScheduleStore {
        return CachedLegacyCredentialScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy credential schedules. Empty fields match all.
    final class LegacyCredentialScheduleQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyCredentialSchedule) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyCredentialSchedule]) -> [LegacyCredentialSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyCredentialSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyCredentialSchedules(_ store: any LegacyCredentialScheduleStore, query: LegacyCredentialScheduleQuery) -> [LegacyCredentialSchedule] {
        return query.apply(store.list())
    }
}
