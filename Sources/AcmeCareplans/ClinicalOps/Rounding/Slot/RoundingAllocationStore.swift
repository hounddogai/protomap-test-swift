import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps rounding allocations by code.
    protocol RoundingAllocationStore {
        func find(_ code: String) -> RoundingAllocation?
        func save(_ item: RoundingAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [RoundingAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRoundingAllocationStore: RoundingAllocationStore {
        var items: [String: RoundingAllocation]
        var order: [String]

        init(items: [String: RoundingAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RoundingAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RoundingAllocation) {
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

        func list() -> [RoundingAllocation] {
            var out: [RoundingAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRoundingAllocationStore() -> any RoundingAllocationStore {
        return MemoryRoundingAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRoundingAllocationStore: RoundingAllocationStore {
        var inner: MemoryRoundingAllocationStore
        var cache: TTLCache<RoundingAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRoundingAllocationStore, cache: TTLCache<RoundingAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RoundingAllocation? {
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

        func save(_ item: RoundingAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RoundingAllocation] {
            return inner.list()
        }
    }

    static func newCachedRoundingAllocationStore(_ inner: MemoryRoundingAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RoundingAllocationStore {
        return CachedRoundingAllocationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rounding allocations. Empty fields match all.
    final class RoundingAllocationQuery {
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

        func matches(_ item: RoundingAllocation) -> Bool {
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

        func apply(_ items: [RoundingAllocation]) -> [RoundingAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RoundingAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRoundingAllocations(_ store: any RoundingAllocationStore, query: RoundingAllocationQuery) -> [RoundingAllocation] {
        return query.apply(store.list())
    }
}
