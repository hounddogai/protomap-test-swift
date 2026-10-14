import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps regional authorization allocations by code.
    protocol RegionalAuthorizationAllocationStore {
        func find(_ code: String) -> RegionalAuthorizationAllocation?
        func save(_ item: RegionalAuthorizationAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalAuthorizationAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalAuthorizationAllocationStore: RegionalAuthorizationAllocationStore {
        var items: [String: RegionalAuthorizationAllocation]
        var order: [String]

        init(items: [String: RegionalAuthorizationAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalAuthorizationAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalAuthorizationAllocation) {
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

        func list() -> [RegionalAuthorizationAllocation] {
            var out: [RegionalAuthorizationAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalAuthorizationAllocationStore() -> any RegionalAuthorizationAllocationStore {
        return MemoryRegionalAuthorizationAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalAuthorizationAllocationStore: RegionalAuthorizationAllocationStore {
        var inner: MemoryRegionalAuthorizationAllocationStore
        var cache: TTLCache<RegionalAuthorizationAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalAuthorizationAllocationStore, cache: TTLCache<RegionalAuthorizationAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalAuthorizationAllocation? {
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

        func save(_ item: RegionalAuthorizationAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalAuthorizationAllocation] {
            return inner.list()
        }
    }

    static func newCachedRegionalAuthorizationAllocationStore(_ inner: MemoryRegionalAuthorizationAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalAuthorizationAllocationStore {
        return CachedRegionalAuthorizationAllocationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional authorization allocations. Empty fields match all.
    final class RegionalAuthorizationAllocationQuery {
        var ward: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalAuthorizationAllocation) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [RegionalAuthorizationAllocation]) -> [RegionalAuthorizationAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalAuthorizationAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalAuthorizationAllocations(_ store: any RegionalAuthorizationAllocationStore, query: RegionalAuthorizationAllocationQuery) -> [RegionalAuthorizationAllocation] {
        return query.apply(store.list())
    }
}
