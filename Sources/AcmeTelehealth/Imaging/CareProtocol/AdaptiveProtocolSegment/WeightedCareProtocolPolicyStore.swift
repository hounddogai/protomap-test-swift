import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps weighted care protocol policies by code.
    protocol WeightedCareProtocolPolicyStore {
        func find(_ code: String) -> WeightedCareProtocolPolicy?
        func save(_ item: WeightedCareProtocolPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedCareProtocolPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedCareProtocolPolicyStore: WeightedCareProtocolPolicyStore {
        var items: [String: WeightedCareProtocolPolicy]
        var order: [String]

        init(items: [String: WeightedCareProtocolPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedCareProtocolPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedCareProtocolPolicy) {
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

        func list() -> [WeightedCareProtocolPolicy] {
            var out: [WeightedCareProtocolPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedCareProtocolPolicyStore() -> any WeightedCareProtocolPolicyStore {
        return MemoryWeightedCareProtocolPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedCareProtocolPolicyStore: WeightedCareProtocolPolicyStore {
        var inner: MemoryWeightedCareProtocolPolicyStore
        var cache: TTLCache<WeightedCareProtocolPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedCareProtocolPolicyStore, cache: TTLCache<WeightedCareProtocolPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedCareProtocolPolicy? {
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

        func save(_ item: WeightedCareProtocolPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedCareProtocolPolicy] {
            return inner.list()
        }
    }

    static func newCachedWeightedCareProtocolPolicyStore(_ inner: MemoryWeightedCareProtocolPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedCareProtocolPolicyStore {
        return CachedWeightedCareProtocolPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted care protocol policies. Empty fields match all.
    final class WeightedCareProtocolPolicyQuery {
        var country: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedCareProtocolPolicy) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedCareProtocolPolicy]) -> [WeightedCareProtocolPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedCareProtocolPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedCareProtocolPolicies(_ store: any WeightedCareProtocolPolicyStore, query: WeightedCareProtocolPolicyQuery) -> [WeightedCareProtocolPolicy] {
        return query.apply(store.list())
    }
}
