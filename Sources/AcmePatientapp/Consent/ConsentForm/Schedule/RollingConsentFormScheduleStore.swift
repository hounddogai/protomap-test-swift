import AcmePlatform
import Foundation

extension Consent {
    /// Keeps rolling consent form schedules by code.
    protocol RollingConsentFormScheduleStore {
        func find(_ code: String) -> RollingConsentFormSchedule?
        func save(_ item: RollingConsentFormSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [RollingConsentFormSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingConsentFormScheduleStore: RollingConsentFormScheduleStore {
        var items: [String: RollingConsentFormSchedule]
        var order: [String]

        init(items: [String: RollingConsentFormSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingConsentFormSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingConsentFormSchedule) {
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

        func list() -> [RollingConsentFormSchedule] {
            var out: [RollingConsentFormSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingConsentFormScheduleStore() -> any RollingConsentFormScheduleStore {
        return MemoryRollingConsentFormScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingConsentFormScheduleStore: RollingConsentFormScheduleStore {
        var inner: MemoryRollingConsentFormScheduleStore
        var cache: TTLCache<RollingConsentFormSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingConsentFormScheduleStore, cache: TTLCache<RollingConsentFormSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingConsentFormSchedule? {
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

        func save(_ item: RollingConsentFormSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingConsentFormSchedule] {
            return inner.list()
        }
    }

    static func newCachedRollingConsentFormScheduleStore(_ inner: MemoryRollingConsentFormScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingConsentFormScheduleStore {
        return CachedRollingConsentFormScheduleStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling consent form schedules. Empty fields match all.
    final class RollingConsentFormScheduleQuery {
        var ward: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingConsentFormSchedule) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [RollingConsentFormSchedule]) -> [RollingConsentFormSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingConsentFormSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingConsentFormSchedules(_ store: any RollingConsentFormScheduleStore, query: RollingConsentFormScheduleQuery) -> [RollingConsentFormSchedule] {
        return query.apply(store.list())
    }
}
