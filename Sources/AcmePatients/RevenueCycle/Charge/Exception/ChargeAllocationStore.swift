import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge allocations by code.
    protocol ChargeAllocationStore {
        func find(_ code: String) -> ChargeAllocation?
        func save(_ item: ChargeAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeAllocationStore: ChargeAllocationStore {
        var items: [String: ChargeAllocation]
        var order: [String]

        init(items: [String: ChargeAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeAllocation) {
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

        func list() -> [ChargeAllocation] {
            var out: [ChargeAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeAllocationStore() -> any ChargeAllocationStore {
        return MemoryChargeAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeAllocationStore: ChargeAllocationStore {
        var inner: MemoryChargeAllocationStore
        var cache: TTLCache<ChargeAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeAllocationStore, cache: TTLCache<ChargeAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeAllocation? {
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

        func save(_ item: ChargeAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeAllocation] {
            return inner.list()
        }
    }

    static func newCachedChargeAllocationStore(_ inner: MemoryChargeAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeAllocationStore {
        return CachedChargeAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge allocations. Empty fields match all.
    final class ChargeAllocationQuery {
        var category: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minWeight: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeAllocation) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeAllocation]) -> [ChargeAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeAllocations(_ store: any ChargeAllocationStore, query: ChargeAllocationQuery) -> [ChargeAllocation] {
        return query.apply(store.list())
    }
}
