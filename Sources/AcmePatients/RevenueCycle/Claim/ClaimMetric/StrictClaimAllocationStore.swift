import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps strict claim allocations by code.
    protocol StrictClaimAllocationStore {
        func find(_ code: String) -> StrictClaimAllocation?
        func save(_ item: StrictClaimAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [StrictClaimAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictClaimAllocationStore: StrictClaimAllocationStore {
        var items: [String: StrictClaimAllocation]
        var order: [String]

        init(items: [String: StrictClaimAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictClaimAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictClaimAllocation) {
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

        func list() -> [StrictClaimAllocation] {
            var out: [StrictClaimAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictClaimAllocationStore() -> any StrictClaimAllocationStore {
        return MemoryStrictClaimAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictClaimAllocationStore: StrictClaimAllocationStore {
        var inner: MemoryStrictClaimAllocationStore
        var cache: TTLCache<StrictClaimAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictClaimAllocationStore, cache: TTLCache<StrictClaimAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictClaimAllocation? {
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

        func save(_ item: StrictClaimAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictClaimAllocation] {
            return inner.list()
        }
    }

    static func newCachedStrictClaimAllocationStore(_ inner: MemoryStrictClaimAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictClaimAllocationStore {
        return CachedStrictClaimAllocationStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict claim allocations. Empty fields match all.
    final class StrictClaimAllocationQuery {
        var region: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictClaimAllocation) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [StrictClaimAllocation]) -> [StrictClaimAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictClaimAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictClaimAllocations(_ store: any StrictClaimAllocationStore, query: StrictClaimAllocationQuery) -> [StrictClaimAllocation] {
        return query.apply(store.list())
    }
}
