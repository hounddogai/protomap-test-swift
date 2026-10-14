import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps fallback discharge plan allocations by code.
    protocol FallbackDischargePlanAllocationStore {
        func find(_ code: String) -> FallbackDischargePlanAllocation?
        func save(_ item: FallbackDischargePlanAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackDischargePlanAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackDischargePlanAllocationStore: FallbackDischargePlanAllocationStore {
        var items: [String: FallbackDischargePlanAllocation]
        var order: [String]

        init(items: [String: FallbackDischargePlanAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackDischargePlanAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackDischargePlanAllocation) {
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

        func list() -> [FallbackDischargePlanAllocation] {
            var out: [FallbackDischargePlanAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackDischargePlanAllocationStore() -> any FallbackDischargePlanAllocationStore {
        return MemoryFallbackDischargePlanAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackDischargePlanAllocationStore: FallbackDischargePlanAllocationStore {
        var inner: MemoryFallbackDischargePlanAllocationStore
        var cache: TTLCache<FallbackDischargePlanAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackDischargePlanAllocationStore, cache: TTLCache<FallbackDischargePlanAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackDischargePlanAllocation? {
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

        func save(_ item: FallbackDischargePlanAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackDischargePlanAllocation] {
            return inner.list()
        }
    }

    static func newCachedFallbackDischargePlanAllocationStore(_ inner: MemoryFallbackDischargePlanAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackDischargePlanAllocationStore {
        return CachedFallbackDischargePlanAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback discharge plan allocations. Empty fields match all.
    final class FallbackDischargePlanAllocationQuery {
        var label: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackDischargePlanAllocation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [FallbackDischargePlanAllocation]) -> [FallbackDischargePlanAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackDischargePlanAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackDischargePlanAllocations(_ store: any FallbackDischargePlanAllocationStore, query: FallbackDischargePlanAllocationQuery) -> [FallbackDischargePlanAllocation] {
        return query.apply(store.list())
    }
}
