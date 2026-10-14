import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps authorization plans by code.
    protocol AuthorizationPlanStore {
        func find(_ code: String) -> AuthorizationPlan?
        func save(_ item: AuthorizationPlan)
        func remove(_ code: String) -> Bool
        func list() -> [AuthorizationPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAuthorizationPlanStore: AuthorizationPlanStore {
        var items: [String: AuthorizationPlan]
        var order: [String]

        init(items: [String: AuthorizationPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AuthorizationPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AuthorizationPlan) {
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

        func list() -> [AuthorizationPlan] {
            var out: [AuthorizationPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAuthorizationPlanStore() -> any AuthorizationPlanStore {
        return MemoryAuthorizationPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAuthorizationPlanStore: AuthorizationPlanStore {
        var inner: MemoryAuthorizationPlanStore
        var cache: TTLCache<AuthorizationPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryAuthorizationPlanStore, cache: TTLCache<AuthorizationPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AuthorizationPlan? {
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

        func save(_ item: AuthorizationPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AuthorizationPlan] {
            return inner.list()
        }
    }

    static func newCachedAuthorizationPlanStore(_ inner: MemoryAuthorizationPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AuthorizationPlanStore {
        return CachedAuthorizationPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects authorization plans. Empty fields match all.
    final class AuthorizationPlanQuery {
        var category: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCopay: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AuthorizationPlan) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [AuthorizationPlan]) -> [AuthorizationPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AuthorizationPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAuthorizationPlans(_ store: any AuthorizationPlanStore, query: AuthorizationPlanQuery) -> [AuthorizationPlan] {
        return query.apply(store.list())
    }
}
