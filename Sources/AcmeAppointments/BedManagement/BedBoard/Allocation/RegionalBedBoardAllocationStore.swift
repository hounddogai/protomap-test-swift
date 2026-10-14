import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps regional bed board allocations by code.
    protocol RegionalBedBoardAllocationStore {
        func find(_ code: String) -> RegionalBedBoardAllocation?
        func save(_ item: RegionalBedBoardAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalBedBoardAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalBedBoardAllocationStore: RegionalBedBoardAllocationStore {
        var items: [String: RegionalBedBoardAllocation]
        var order: [String]

        init(items: [String: RegionalBedBoardAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalBedBoardAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalBedBoardAllocation) {
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

        func list() -> [RegionalBedBoardAllocation] {
            var out: [RegionalBedBoardAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalBedBoardAllocationStore() -> any RegionalBedBoardAllocationStore {
        return MemoryRegionalBedBoardAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalBedBoardAllocationStore: RegionalBedBoardAllocationStore {
        var inner: MemoryRegionalBedBoardAllocationStore
        var cache: TTLCache<RegionalBedBoardAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalBedBoardAllocationStore, cache: TTLCache<RegionalBedBoardAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalBedBoardAllocation? {
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

        func save(_ item: RegionalBedBoardAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalBedBoardAllocation] {
            return inner.list()
        }
    }

    static func newCachedRegionalBedBoardAllocationStore(_ inner: MemoryRegionalBedBoardAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalBedBoardAllocationStore {
        return CachedRegionalBedBoardAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional bed board allocations. Empty fields match all.
    final class RegionalBedBoardAllocationQuery {
        var unit: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minWeight: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalBedBoardAllocation) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [RegionalBedBoardAllocation]) -> [RegionalBedBoardAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalBedBoardAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalBedBoardAllocations(_ store: any RegionalBedBoardAllocationStore, query: RegionalBedBoardAllocationQuery) -> [RegionalBedBoardAllocation] {
        return query.apply(store.list())
    }
}
