import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps tiered care protocol allocations by code.
    protocol TieredCareProtocolAllocationStore {
        func find(_ code: String) -> TieredCareProtocolAllocation?
        func save(_ item: TieredCareProtocolAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [TieredCareProtocolAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredCareProtocolAllocationStore: TieredCareProtocolAllocationStore {
        var items: [String: TieredCareProtocolAllocation]
        var order: [String]

        init(items: [String: TieredCareProtocolAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredCareProtocolAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredCareProtocolAllocation) {
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

        func list() -> [TieredCareProtocolAllocation] {
            var out: [TieredCareProtocolAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredCareProtocolAllocationStore() -> any TieredCareProtocolAllocationStore {
        return MemoryTieredCareProtocolAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredCareProtocolAllocationStore: TieredCareProtocolAllocationStore {
        var inner: MemoryTieredCareProtocolAllocationStore
        var cache: TTLCache<TieredCareProtocolAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredCareProtocolAllocationStore, cache: TTLCache<TieredCareProtocolAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredCareProtocolAllocation? {
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

        func save(_ item: TieredCareProtocolAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredCareProtocolAllocation] {
            return inner.list()
        }
    }

    static func newCachedTieredCareProtocolAllocationStore(_ inner: MemoryTieredCareProtocolAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredCareProtocolAllocationStore {
        return CachedTieredCareProtocolAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered care protocol allocations. Empty fields match all.
    final class TieredCareProtocolAllocationQuery {
        var unit: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRefills: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredCareProtocolAllocation) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredCareProtocolAllocation]) -> [TieredCareProtocolAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredCareProtocolAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredCareProtocolAllocations(_ store: any TieredCareProtocolAllocationStore, query: TieredCareProtocolAllocationQuery) -> [TieredCareProtocolAllocation] {
        return query.apply(store.list())
    }
}
