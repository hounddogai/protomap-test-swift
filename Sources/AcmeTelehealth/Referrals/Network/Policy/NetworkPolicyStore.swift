import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network policies by code.
    protocol NetworkPolicyStore {
        func find(_ code: String) -> NetworkPolicy?
        func save(_ item: NetworkPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkPolicyStore: NetworkPolicyStore {
        var items: [String: NetworkPolicy]
        var order: [String]

        init(items: [String: NetworkPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkPolicy) {
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

        func list() -> [NetworkPolicy] {
            var out: [NetworkPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkPolicyStore() -> any NetworkPolicyStore {
        return MemoryNetworkPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkPolicyStore: NetworkPolicyStore {
        var inner: MemoryNetworkPolicyStore
        var cache: TTLCache<NetworkPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkPolicyStore, cache: TTLCache<NetworkPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkPolicy? {
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

        func save(_ item: NetworkPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkPolicy] {
            return inner.list()
        }
    }

    static func newCachedNetworkPolicyStore(_ inner: MemoryNetworkPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkPolicyStore {
        return CachedNetworkPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network policies. Empty fields match all.
    final class NetworkPolicyQuery {
        var facility: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkPolicy) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkPolicy]) -> [NetworkPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkPolicies(_ store: any NetworkPolicyStore, query: NetworkPolicyQuery) -> [NetworkPolicy] {
        return query.apply(store.list())
    }
}
