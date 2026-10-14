import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps dispense allocations by code.
    protocol DispenseAllocationStore {
        func find(_ code: String) -> DispenseAllocation?
        func save(_ item: DispenseAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [DispenseAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDispenseAllocationStore: DispenseAllocationStore {
        var items: [String: DispenseAllocation]
        var order: [String]

        init(items: [String: DispenseAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DispenseAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DispenseAllocation) {
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

        func list() -> [DispenseAllocation] {
            var out: [DispenseAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDispenseAllocationStore() -> any DispenseAllocationStore {
        return MemoryDispenseAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDispenseAllocationStore: DispenseAllocationStore {
        var inner: MemoryDispenseAllocationStore
        var cache: TTLCache<DispenseAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryDispenseAllocationStore, cache: TTLCache<DispenseAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DispenseAllocation? {
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

        func save(_ item: DispenseAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DispenseAllocation] {
            return inner.list()
        }
    }

    static func newCachedDispenseAllocationStore(_ inner: MemoryDispenseAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DispenseAllocationStore {
        return CachedDispenseAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects dispense allocations. Empty fields match all.
    final class DispenseAllocationQuery {
        var label: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DispenseAllocation) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [DispenseAllocation]) -> [DispenseAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DispenseAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDispenseAllocations(_ store: any DispenseAllocationStore, query: DispenseAllocationQuery) -> [DispenseAllocation] {
        return query.apply(store.list())
    }
}
