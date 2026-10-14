import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps weighted substitution allocations by code.
    protocol WeightedSubstitutionAllocationStore {
        func find(_ code: String) -> WeightedSubstitutionAllocation?
        func save(_ item: WeightedSubstitutionAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedSubstitutionAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedSubstitutionAllocationStore: WeightedSubstitutionAllocationStore {
        var items: [String: WeightedSubstitutionAllocation]
        var order: [String]

        init(items: [String: WeightedSubstitutionAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedSubstitutionAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedSubstitutionAllocation) {
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

        func list() -> [WeightedSubstitutionAllocation] {
            var out: [WeightedSubstitutionAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedSubstitutionAllocationStore() -> any WeightedSubstitutionAllocationStore {
        return MemoryWeightedSubstitutionAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedSubstitutionAllocationStore: WeightedSubstitutionAllocationStore {
        var inner: MemoryWeightedSubstitutionAllocationStore
        var cache: TTLCache<WeightedSubstitutionAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedSubstitutionAllocationStore, cache: TTLCache<WeightedSubstitutionAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedSubstitutionAllocation? {
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

        func save(_ item: WeightedSubstitutionAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedSubstitutionAllocation] {
            return inner.list()
        }
    }

    static func newCachedWeightedSubstitutionAllocationStore(_ inner: MemoryWeightedSubstitutionAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedSubstitutionAllocationStore {
        return CachedWeightedSubstitutionAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted substitution allocations. Empty fields match all.
    final class WeightedSubstitutionAllocationQuery {
        var source: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(source: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.source = source
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedSubstitutionAllocation) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedSubstitutionAllocation]) -> [WeightedSubstitutionAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedSubstitutionAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedSubstitutionAllocations(_ store: any WeightedSubstitutionAllocationStore, query: WeightedSubstitutionAllocationQuery) -> [WeightedSubstitutionAllocation] {
        return query.apply(store.list())
    }
}
