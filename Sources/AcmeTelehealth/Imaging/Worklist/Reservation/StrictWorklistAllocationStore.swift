import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps strict worklist allocations by code.
    protocol StrictWorklistAllocationStore {
        func find(_ code: String) -> StrictWorklistAllocation?
        func save(_ item: StrictWorklistAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [StrictWorklistAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictWorklistAllocationStore: StrictWorklistAllocationStore {
        var items: [String: StrictWorklistAllocation]
        var order: [String]

        init(items: [String: StrictWorklistAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictWorklistAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictWorklistAllocation) {
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

        func list() -> [StrictWorklistAllocation] {
            var out: [StrictWorklistAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictWorklistAllocationStore() -> any StrictWorklistAllocationStore {
        return MemoryStrictWorklistAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictWorklistAllocationStore: StrictWorklistAllocationStore {
        var inner: MemoryStrictWorklistAllocationStore
        var cache: TTLCache<StrictWorklistAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictWorklistAllocationStore, cache: TTLCache<StrictWorklistAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictWorklistAllocation? {
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

        func save(_ item: StrictWorklistAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictWorklistAllocation] {
            return inner.list()
        }
    }

    static func newCachedStrictWorklistAllocationStore(_ inner: MemoryStrictWorklistAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictWorklistAllocationStore {
        return CachedStrictWorklistAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict worklist allocations. Empty fields match all.
    final class StrictWorklistAllocationQuery {
        var name: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictWorklistAllocation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [StrictWorklistAllocation]) -> [StrictWorklistAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictWorklistAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictWorklistAllocations(_ store: any StrictWorklistAllocationStore, query: StrictWorklistAllocationQuery) -> [StrictWorklistAllocation] {
        return query.apply(store.list())
    }
}
