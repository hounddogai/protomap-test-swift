import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim allocations by code.
    protocol ClaimAllocationStore {
        func find(_ code: String) -> ClaimAllocation?
        func save(_ item: ClaimAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimAllocationStore: ClaimAllocationStore {
        var items: [String: ClaimAllocation]
        var order: [String]

        init(items: [String: ClaimAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimAllocation) {
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

        func list() -> [ClaimAllocation] {
            var out: [ClaimAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimAllocationStore() -> any ClaimAllocationStore {
        return MemoryClaimAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimAllocationStore: ClaimAllocationStore {
        var inner: MemoryClaimAllocationStore
        var cache: TTLCache<ClaimAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimAllocationStore, cache: TTLCache<ClaimAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimAllocation? {
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

        func save(_ item: ClaimAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimAllocation] {
            return inner.list()
        }
    }

    static func newCachedClaimAllocationStore(_ inner: MemoryClaimAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimAllocationStore {
        return CachedClaimAllocationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim allocations. Empty fields match all.
    final class ClaimAllocationQuery {
        var name: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimAllocation) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimAllocation]) -> [ClaimAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimAllocations(_ store: any ClaimAllocationStore, query: ClaimAllocationQuery) -> [ClaimAllocation] {
        return query.apply(store.list())
    }
}
