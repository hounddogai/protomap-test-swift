import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps weighted charge policies by code.
    protocol WeightedChargePolicyStore {
        func find(_ code: String) -> WeightedChargePolicy?
        func save(_ item: WeightedChargePolicy)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedChargePolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedChargePolicyStore: WeightedChargePolicyStore {
        var items: [String: WeightedChargePolicy]
        var order: [String]

        init(items: [String: WeightedChargePolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedChargePolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedChargePolicy) {
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

        func list() -> [WeightedChargePolicy] {
            var out: [WeightedChargePolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedChargePolicyStore() -> any WeightedChargePolicyStore {
        return MemoryWeightedChargePolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedChargePolicyStore: WeightedChargePolicyStore {
        var inner: MemoryWeightedChargePolicyStore
        var cache: TTLCache<WeightedChargePolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedChargePolicyStore, cache: TTLCache<WeightedChargePolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedChargePolicy? {
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

        func save(_ item: WeightedChargePolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedChargePolicy] {
            return inner.list()
        }
    }

    static func newCachedWeightedChargePolicyStore(_ inner: MemoryWeightedChargePolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedChargePolicyStore {
        return CachedWeightedChargePolicyStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted charge policies. Empty fields match all.
    final class WeightedChargePolicyQuery {
        var region: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedChargePolicy) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedChargePolicy]) -> [WeightedChargePolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedChargePolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedChargePolicies(_ store: any WeightedChargePolicyStore, query: WeightedChargePolicyQuery) -> [WeightedChargePolicy] {
        return query.apply(store.list())
    }
}
