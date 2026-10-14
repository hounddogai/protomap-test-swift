import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered remittance allocations by code.
    protocol TieredRemittanceAllocationStore {
        func find(_ code: String) -> TieredRemittanceAllocation?
        func save(_ item: TieredRemittanceAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [TieredRemittanceAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredRemittanceAllocationStore: TieredRemittanceAllocationStore {
        var items: [String: TieredRemittanceAllocation]
        var order: [String]

        init(items: [String: TieredRemittanceAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredRemittanceAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredRemittanceAllocation) {
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

        func list() -> [TieredRemittanceAllocation] {
            var out: [TieredRemittanceAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredRemittanceAllocationStore() -> any TieredRemittanceAllocationStore {
        return MemoryTieredRemittanceAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredRemittanceAllocationStore: TieredRemittanceAllocationStore {
        var inner: MemoryTieredRemittanceAllocationStore
        var cache: TTLCache<TieredRemittanceAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredRemittanceAllocationStore, cache: TTLCache<TieredRemittanceAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredRemittanceAllocation? {
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

        func save(_ item: TieredRemittanceAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredRemittanceAllocation] {
            return inner.list()
        }
    }

    static func newCachedTieredRemittanceAllocationStore(_ inner: MemoryTieredRemittanceAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredRemittanceAllocationStore {
        return CachedTieredRemittanceAllocationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered remittance allocations. Empty fields match all.
    final class TieredRemittanceAllocationQuery {
        var category: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredRemittanceAllocation) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredRemittanceAllocation]) -> [TieredRemittanceAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredRemittanceAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredRemittanceAllocations(_ store: any TieredRemittanceAllocationStore, query: TieredRemittanceAllocationQuery) -> [TieredRemittanceAllocation] {
        return query.apply(store.list())
    }
}
