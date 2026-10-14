import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps global formulary allocations by code.
    protocol GlobalFormularyAllocationStore {
        func find(_ code: String) -> GlobalFormularyAllocation?
        func save(_ item: GlobalFormularyAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalFormularyAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalFormularyAllocationStore: GlobalFormularyAllocationStore {
        var items: [String: GlobalFormularyAllocation]
        var order: [String]

        init(items: [String: GlobalFormularyAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalFormularyAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalFormularyAllocation) {
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

        func list() -> [GlobalFormularyAllocation] {
            var out: [GlobalFormularyAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalFormularyAllocationStore() -> any GlobalFormularyAllocationStore {
        return MemoryGlobalFormularyAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalFormularyAllocationStore: GlobalFormularyAllocationStore {
        var inner: MemoryGlobalFormularyAllocationStore
        var cache: TTLCache<GlobalFormularyAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalFormularyAllocationStore, cache: TTLCache<GlobalFormularyAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalFormularyAllocation? {
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

        func save(_ item: GlobalFormularyAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalFormularyAllocation] {
            return inner.list()
        }
    }

    static func newCachedGlobalFormularyAllocationStore(_ inner: MemoryGlobalFormularyAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalFormularyAllocationStore {
        return CachedGlobalFormularyAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global formulary allocations. Empty fields match all.
    final class GlobalFormularyAllocationQuery {
        var category: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalFormularyAllocation) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [GlobalFormularyAllocation]) -> [GlobalFormularyAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalFormularyAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalFormularyAllocations(_ store: any GlobalFormularyAllocationStore, query: GlobalFormularyAllocationQuery) -> [GlobalFormularyAllocation] {
        return query.apply(store.list())
    }
}
