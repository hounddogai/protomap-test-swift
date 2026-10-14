import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel allocations by code.
    protocol PanelAllocationStore {
        func find(_ code: String) -> PanelAllocation?
        func save(_ item: PanelAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [PanelAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelAllocationStore: PanelAllocationStore {
        var items: [String: PanelAllocation]
        var order: [String]

        init(items: [String: PanelAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelAllocation) {
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

        func list() -> [PanelAllocation] {
            var out: [PanelAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelAllocationStore() -> any PanelAllocationStore {
        return MemoryPanelAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelAllocationStore: PanelAllocationStore {
        var inner: MemoryPanelAllocationStore
        var cache: TTLCache<PanelAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelAllocationStore, cache: TTLCache<PanelAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelAllocation? {
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

        func save(_ item: PanelAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelAllocation] {
            return inner.list()
        }
    }

    static func newCachedPanelAllocationStore(_ inner: MemoryPanelAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelAllocationStore {
        return CachedPanelAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel allocations. Empty fields match all.
    final class PanelAllocationQuery {
        var ward: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelAllocation) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [PanelAllocation]) -> [PanelAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelAllocations(_ store: any PanelAllocationStore, query: PanelAllocationQuery) -> [PanelAllocation] {
        return query.apply(store.list())
    }
}
