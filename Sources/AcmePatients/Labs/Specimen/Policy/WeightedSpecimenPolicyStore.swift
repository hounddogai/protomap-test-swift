import AcmePlatform
import Foundation

extension Labs {
    /// Keeps weighted specimen policies by code.
    protocol WeightedSpecimenPolicyStore {
        func find(_ code: String) -> WeightedSpecimenPolicy?
        func save(_ item: WeightedSpecimenPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSpecimenPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSpecimenPolicyStore: WeightedSpecimenPolicyStore {
        var items: [String: WeightedSpecimenPolicy]
        var order: [String]

        init(items: [String: WeightedSpecimenPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSpecimenPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSpecimenPolicy) {
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

        func list() -> [WeightedSpecimenPolicy] {
            var out: [WeightedSpecimenPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSpecimenPolicyStore() -> any WeightedSpecimenPolicyStore {
        return MemoryWeightedSpecimenPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSpecimenPolicyStore: WeightedSpecimenPolicyStore {
        var inner: MemoryWeightedSpecimenPolicyStore
        var cache: TTLCache<WeightedSpecimenPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSpecimenPolicyStore, cache: TTLCache<WeightedSpecimenPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSpecimenPolicy? {
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

        func save(_ item: WeightedSpecimenPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSpecimenPolicy] {
            return inner.list()
        }
    }

    static func newCachedWeightedSpecimenPolicyStore(_ inner: MemoryWeightedSpecimenPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSpecimenPolicyStore {
        return CachedWeightedSpecimenPolicyStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted specimen policies. Empty fields match all.
    final class WeightedSpecimenPolicyQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedSpecimenPolicy) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [WeightedSpecimenPolicy]) -> [WeightedSpecimenPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSpecimenPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSpecimenPolicies(_ store: any WeightedSpecimenPolicyStore, query: WeightedSpecimenPolicyQuery) -> [WeightedSpecimenPolicy] {
        return query.apply(store.list())
    }
}
