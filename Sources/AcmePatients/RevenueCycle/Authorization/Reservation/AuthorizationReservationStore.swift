import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization reservations by code.
    protocol AuthorizationReservationStore {
        func find(_ code: String) -> AuthorizationReservation?
        func save(_ item: AuthorizationReservation)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationReservation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationReservationStore: AuthorizationReservationStore {
        var items: [String: AuthorizationReservation]
        var order: [String]

        init(items: [String: AuthorizationReservation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationReservation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationReservation) {
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

        func list() -> [AuthorizationReservation] {
            var out: [AuthorizationReservation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationReservationStore() -> any AuthorizationReservationStore {
        return MemoryAuthorizationReservationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationReservationStore: AuthorizationReservationStore {
        var inner: MemoryAuthorizationReservationStore
        var cache: TTLCache<AuthorizationReservation>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationReservationStore, cache: TTLCache<AuthorizationReservation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationReservation? {
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

        func save(_ item: AuthorizationReservation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationReservation] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationReservationStore(_ inner: MemoryAuthorizationReservationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationReservationStore {
        return CachedAuthorizationReservationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization reservations. Empty fields match all.
    final class AuthorizationReservationQuery {
        var title: String
        var minVersion: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minVersion: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minVersion = minVersion
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationReservation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [AuthorizationReservation]) -> [AuthorizationReservation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationReservation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationReservations(_ store: any AuthorizationReservationStore, query: AuthorizationReservationQuery) -> [AuthorizationReservation] {
        return query.apply(store.list())
    }
}
