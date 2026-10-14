import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps pending recall allocations by code.
    protocol PendingRecallAllocationStore {
        func find(_ code: String) -> PendingRecallAllocation?
        func save(_ item: PendingRecallAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRecallAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRecallAllocationStore: PendingRecallAllocationStore {
        var items: [String: PendingRecallAllocation]
        var order: [String]

        init(items: [String: PendingRecallAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRecallAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRecallAllocation) {
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

        func list() -> [PendingRecallAllocation] {
            var out: [PendingRecallAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRecallAllocationStore() -> any PendingRecallAllocationStore {
        return MemoryPendingRecallAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRecallAllocationStore: PendingRecallAllocationStore {
        var inner: MemoryPendingRecallAllocationStore
        var cache: TTLCache<PendingRecallAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRecallAllocationStore, cache: TTLCache<PendingRecallAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRecallAllocation? {
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

        func save(_ item: PendingRecallAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRecallAllocation] {
            return inner.list()
        }
    }

    static func newCachedPendingRecallAllocationStore(_ inner: MemoryPendingRecallAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRecallAllocationStore {
        return CachedPendingRecallAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending recall allocations. Empty fields match all.
    final class PendingRecallAllocationQuery {
        var category: String
        var minCost: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCost: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCost = minCost
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRecallAllocation) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.cost < minCost {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingRecallAllocation]) -> [PendingRecallAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRecallAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRecallAllocations(_ store: any PendingRecallAllocationStore, query: PendingRecallAllocationQuery) -> [PendingRecallAllocation] {
        return query.apply(store.list())
    }
}
