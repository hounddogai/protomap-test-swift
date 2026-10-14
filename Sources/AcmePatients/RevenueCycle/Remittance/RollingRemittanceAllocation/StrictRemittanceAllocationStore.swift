import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps strict remittance allocations by code.
    protocol StrictRemittanceAllocationStore {
        func find(_ code: String) -> StrictRemittanceAllocation?
        func save(_ item: StrictRemittanceAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [StrictRemittanceAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictRemittanceAllocationStore: StrictRemittanceAllocationStore {
        var items: [String: StrictRemittanceAllocation]
        var order: [String]

        init(items: [String: StrictRemittanceAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictRemittanceAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictRemittanceAllocation) {
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

        func list() -> [StrictRemittanceAllocation] {
            var out: [StrictRemittanceAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictRemittanceAllocationStore() -> any StrictRemittanceAllocationStore {
        return MemoryStrictRemittanceAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictRemittanceAllocationStore: StrictRemittanceAllocationStore {
        var inner: MemoryStrictRemittanceAllocationStore
        var cache: TTLCache<StrictRemittanceAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictRemittanceAllocationStore, cache: TTLCache<StrictRemittanceAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictRemittanceAllocation? {
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

        func save(_ item: StrictRemittanceAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictRemittanceAllocation] {
            return inner.list()
        }
    }

    static func newCachedStrictRemittanceAllocationStore(_ inner: MemoryStrictRemittanceAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictRemittanceAllocationStore {
        return CachedStrictRemittanceAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict remittance allocations. Empty fields match all.
    final class StrictRemittanceAllocationQuery {
        var name: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minPriority: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictRemittanceAllocation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictRemittanceAllocation]) -> [StrictRemittanceAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictRemittanceAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictRemittanceAllocations(_ store: any StrictRemittanceAllocationStore, query: StrictRemittanceAllocationQuery) -> [StrictRemittanceAllocation] {
        return query.apply(store.list())
    }
}
