import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization assignments by code.
    protocol AuthorizationAssignmentStore {
        func find(_ code: String) -> AuthorizationAssignment?
        func save(_ item: AuthorizationAssignment)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationAssignment]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationAssignmentStore: AuthorizationAssignmentStore {
        var items: [String: AuthorizationAssignment]
        var order: [String]

        init(items: [String: AuthorizationAssignment], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationAssignment? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationAssignment) {
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

        func list() -> [AuthorizationAssignment] {
            var out: [AuthorizationAssignment] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationAssignmentStore() -> any AuthorizationAssignmentStore {
        return MemoryAuthorizationAssignmentStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationAssignmentStore: AuthorizationAssignmentStore {
        var inner: MemoryAuthorizationAssignmentStore
        var cache: TTLCache<AuthorizationAssignment>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationAssignmentStore, cache: TTLCache<AuthorizationAssignment>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationAssignment? {
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

        func save(_ item: AuthorizationAssignment) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationAssignment] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationAssignmentStore(_ inner: MemoryAuthorizationAssignmentStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationAssignmentStore {
        return CachedAuthorizationAssignmentStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization assignments. Empty fields match all.
    final class AuthorizationAssignmentQuery {
        var facility: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCopay: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationAssignment) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationAssignment]) -> [AuthorizationAssignment] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationAssignment) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationAssignments(_ store: any AuthorizationAssignmentStore, query: AuthorizationAssignmentQuery) -> [AuthorizationAssignment] {
        return query.apply(store.list())
    }
}
