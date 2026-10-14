import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization schedules by code.
    protocol AuthorizationScheduleStore {
        func find(_ code: String) -> AuthorizationSchedule?
        func save(_ item: AuthorizationSchedule)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationSchedule]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationScheduleStore: AuthorizationScheduleStore {
        var items: [String: AuthorizationSchedule]
        var order: [String]

        init(items: [String: AuthorizationSchedule], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationSchedule? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationSchedule) {
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

        func list() -> [AuthorizationSchedule] {
            var out: [AuthorizationSchedule] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationScheduleStore() -> any AuthorizationScheduleStore {
        return MemoryAuthorizationScheduleStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationScheduleStore: AuthorizationScheduleStore {
        var inner: MemoryAuthorizationScheduleStore
        var cache: TTLCache<AuthorizationSchedule>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationScheduleStore, cache: TTLCache<AuthorizationSchedule>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationSchedule? {
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

        func save(_ item: AuthorizationSchedule) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationSchedule] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationScheduleStore(_ inner: MemoryAuthorizationScheduleStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationScheduleStore {
        return CachedAuthorizationScheduleStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization schedules. Empty fields match all.
    final class AuthorizationScheduleQuery {
        var segment: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minBudget: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationSchedule) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationSchedule]) -> [AuthorizationSchedule] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationSchedule) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationSchedules(_ store: any AuthorizationScheduleStore, query: AuthorizationScheduleQuery) -> [AuthorizationSchedule] {
        return query.apply(store.list())
    }
}
