import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization milestones by code.
    protocol AuthorizationMilestoneStore {
        func find(_ code: String) -> AuthorizationMilestone?
        func save(_ item: AuthorizationMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationMilestoneStore: AuthorizationMilestoneStore {
        var items: [String: AuthorizationMilestone]
        var order: [String]

        init(items: [String: AuthorizationMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationMilestone) {
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

        func list() -> [AuthorizationMilestone] {
            var out: [AuthorizationMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationMilestoneStore() -> any AuthorizationMilestoneStore {
        return MemoryAuthorizationMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationMilestoneStore: AuthorizationMilestoneStore {
        var inner: MemoryAuthorizationMilestoneStore
        var cache: TTLCache<AuthorizationMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationMilestoneStore, cache: TTLCache<AuthorizationMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationMilestone? {
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

        func save(_ item: AuthorizationMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationMilestone] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationMilestoneStore(_ inner: MemoryAuthorizationMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationMilestoneStore {
        return CachedAuthorizationMilestoneStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization milestones. Empty fields match all.
    final class AuthorizationMilestoneQuery {
        var facility: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minRatio: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationMilestone) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AuthorizationMilestone]) -> [AuthorizationMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationMilestones(_ store: any AuthorizationMilestoneStore, query: AuthorizationMilestoneQuery) -> [AuthorizationMilestone] {
        return query.apply(store.list())
    }
}
