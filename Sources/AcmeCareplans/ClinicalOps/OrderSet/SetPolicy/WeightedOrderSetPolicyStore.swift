import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps weighted order set policies by code.
    protocol WeightedOrderSetPolicyStore {
        func find(_ code: String) -> WeightedOrderSetPolicy?
        func save(_ item: WeightedOrderSetPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedOrderSetPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedOrderSetPolicyStore: WeightedOrderSetPolicyStore {
        var items: [String: WeightedOrderSetPolicy]
        var order: [String]

        init(items: [String: WeightedOrderSetPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedOrderSetPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedOrderSetPolicy) {
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

        func list() -> [WeightedOrderSetPolicy] {
            var out: [WeightedOrderSetPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedOrderSetPolicyStore() -> any WeightedOrderSetPolicyStore {
        return MemoryWeightedOrderSetPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedOrderSetPolicyStore: WeightedOrderSetPolicyStore {
        var inner: MemoryWeightedOrderSetPolicyStore
        var cache: TTLCache<WeightedOrderSetPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedOrderSetPolicyStore, cache: TTLCache<WeightedOrderSetPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedOrderSetPolicy? {
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

        func save(_ item: WeightedOrderSetPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedOrderSetPolicy] {
            return inner.list()
        }
    }

    static func newCachedWeightedOrderSetPolicyStore(_ inner: MemoryWeightedOrderSetPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedOrderSetPolicyStore {
        return CachedWeightedOrderSetPolicyStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted order set policies. Empty fields match all.
    final class WeightedOrderSetPolicyQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedOrderSetPolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedOrderSetPolicy]) -> [WeightedOrderSetPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedOrderSetPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedOrderSetPolicies(_ store: any WeightedOrderSetPolicyStore, query: WeightedOrderSetPolicyQuery) -> [WeightedOrderSetPolicy] {
        return query.apply(store.list())
    }
}
