import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set allocations by code.
    protocol OrderSetAllocationStore {
        func find(_ code: String) -> OrderSetAllocation?
        func save(_ item: OrderSetAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetAllocationStore: OrderSetAllocationStore {
        var items: [String: OrderSetAllocation]
        var order: [String]

        init(items: [String: OrderSetAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetAllocation) {
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

        func list() -> [OrderSetAllocation] {
            var out: [OrderSetAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetAllocationStore() -> any OrderSetAllocationStore {
        return MemoryOrderSetAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetAllocationStore: OrderSetAllocationStore {
        var inner: MemoryOrderSetAllocationStore
        var cache: TTLCache<OrderSetAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetAllocationStore, cache: TTLCache<OrderSetAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetAllocation? {
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

        func save(_ item: OrderSetAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetAllocation] {
            return inner.list()
        }
    }

    static func newCachedOrderSetAllocationStore(_ inner: MemoryOrderSetAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetAllocationStore {
        return CachedOrderSetAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set allocations. Empty fields match all.
    final class OrderSetAllocationQuery {
        var source: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetAllocation) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetAllocation]) -> [OrderSetAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetAllocations(_ store: any OrderSetAllocationStore, query: OrderSetAllocationQuery) -> [OrderSetAllocation] {
        return query.apply(store.list())
    }
}
