import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending network policies by code.
    protocol PendingNetworkPolicyStore {
        func find(_ code: String) -> PendingNetworkPolicy?
        func save(_ item: PendingNetworkPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [PendingNetworkPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingNetworkPolicyStore: PendingNetworkPolicyStore {
        var items: [String: PendingNetworkPolicy]
        var order: [String]

        init(items: [String: PendingNetworkPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingNetworkPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingNetworkPolicy) {
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

        func list() -> [PendingNetworkPolicy] {
            var out: [PendingNetworkPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingNetworkPolicyStore() -> any PendingNetworkPolicyStore {
        return MemoryPendingNetworkPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingNetworkPolicyStore: PendingNetworkPolicyStore {
        var inner: MemoryPendingNetworkPolicyStore
        var cache: TTLCache<PendingNetworkPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingNetworkPolicyStore, cache: TTLCache<PendingNetworkPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingNetworkPolicy? {
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

        func save(_ item: PendingNetworkPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingNetworkPolicy] {
            return inner.list()
        }
    }

    static func newCachedPendingNetworkPolicyStore(_ inner: MemoryPendingNetworkPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingNetworkPolicyStore {
        return CachedPendingNetworkPolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending network policies. Empty fields match all.
    final class PendingNetworkPolicyQuery {
        var locale: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(locale: String, minBudget: Double, statuses: [String], limit: Int) {
            self.locale = locale
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingNetworkPolicy) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
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

        func apply(_ items: [PendingNetworkPolicy]) -> [PendingNetworkPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingNetworkPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingNetworkPolicies(_ store: any PendingNetworkPolicyStore, query: PendingNetworkPolicyQuery) -> [PendingNetworkPolicy] {
        return query.apply(store.list())
    }
}
