import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps bed board allocations by code.
    protocol BedBoardAllocationStore {
        func find(_ code: String) -> BedBoardAllocation?
        func save(_ item: BedBoardAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [BedBoardAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryBedBoardAllocationStore: BedBoardAllocationStore {
        var items: [String: BedBoardAllocation]
        var order: [String]

        init(items: [String: BedBoardAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> BedBoardAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: BedBoardAllocation) {
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

        func list() -> [BedBoardAllocation] {
            var out: [BedBoardAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryBedBoardAllocationStore() -> any BedBoardAllocationStore {
        return MemoryBedBoardAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedBedBoardAllocationStore: BedBoardAllocationStore {
        var inner: MemoryBedBoardAllocationStore
        var cache: TTLCache<BedBoardAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryBedBoardAllocationStore, cache: TTLCache<BedBoardAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> BedBoardAllocation? {
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

        func save(_ item: BedBoardAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [BedBoardAllocation] {
            return inner.list()
        }
    }

    static func newCachedBedBoardAllocationStore(_ inner: MemoryBedBoardAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any BedBoardAllocationStore {
        return CachedBedBoardAllocationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects bed board allocations. Empty fields match all.
    final class BedBoardAllocationQuery {
        var segment: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: BedBoardAllocation) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [BedBoardAllocation]) -> [BedBoardAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: BedBoardAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findBedBoardAllocations(_ store: any BedBoardAllocationStore, query: BedBoardAllocationQuery) -> [BedBoardAllocation] {
        return query.apply(store.list())
    }
}
