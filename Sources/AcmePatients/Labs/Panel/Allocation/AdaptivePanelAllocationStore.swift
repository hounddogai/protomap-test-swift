import AcmePlatform
import Foundation

extension Labs {
    /// Keeps adaptive panel allocations by code.
    protocol AdaptivePanelAllocationStore {
        func find(_ code: String) -> AdaptivePanelAllocation?
        func save(_ item: AdaptivePanelAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptivePanelAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptivePanelAllocationStore: AdaptivePanelAllocationStore {
        var items: [String: AdaptivePanelAllocation]
        var order: [String]

        init(items: [String: AdaptivePanelAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptivePanelAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptivePanelAllocation) {
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

        func list() -> [AdaptivePanelAllocation] {
            var out: [AdaptivePanelAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptivePanelAllocationStore() -> any AdaptivePanelAllocationStore {
        return MemoryAdaptivePanelAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptivePanelAllocationStore: AdaptivePanelAllocationStore {
        var inner: MemoryAdaptivePanelAllocationStore
        var cache: TTLCache<AdaptivePanelAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptivePanelAllocationStore, cache: TTLCache<AdaptivePanelAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptivePanelAllocation? {
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

        func save(_ item: AdaptivePanelAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptivePanelAllocation] {
            return inner.list()
        }
    }

    static func newCachedAdaptivePanelAllocationStore(_ inner: MemoryAdaptivePanelAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptivePanelAllocationStore {
        return CachedAdaptivePanelAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive panel allocations. Empty fields match all.
    final class AdaptivePanelAllocationQuery {
        var facility: String
        var minCopay: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCopay: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCopay = minCopay
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptivePanelAllocation) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.copay < minCopay {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptivePanelAllocation]) -> [AdaptivePanelAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptivePanelAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptivePanelAllocations(_ store: any AdaptivePanelAllocationStore, query: AdaptivePanelAllocationQuery) -> [AdaptivePanelAllocation] {
        return query.apply(store.list())
    }
}
