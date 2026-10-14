import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up allocations by code.
    protocol FollowUpAllocationStore {
        func find(_ code: String) -> FollowUpAllocation?
        func save(_ item: FollowUpAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpAllocationStore: FollowUpAllocationStore {
        var items: [String: FollowUpAllocation]
        var order: [String]

        init(items: [String: FollowUpAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpAllocation) {
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

        func list() -> [FollowUpAllocation] {
            var out: [FollowUpAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpAllocationStore() -> any FollowUpAllocationStore {
        return MemoryFollowUpAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpAllocationStore: FollowUpAllocationStore {
        var inner: MemoryFollowUpAllocationStore
        var cache: TTLCache<FollowUpAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpAllocationStore, cache: TTLCache<FollowUpAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpAllocation? {
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

        func save(_ item: FollowUpAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpAllocation] {
            return inner.list()
        }
    }

    static func newCachedFollowUpAllocationStore(_ inner: MemoryFollowUpAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpAllocationStore {
        return CachedFollowUpAllocationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up allocations. Empty fields match all.
    final class FollowUpAllocationQuery {
        var unit: String
        var minRatio: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minRatio: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRatio = minRatio
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpAllocation) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.ratio < minRatio {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpAllocation]) -> [FollowUpAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpAllocations(_ store: any FollowUpAllocationStore, query: FollowUpAllocationQuery) -> [FollowUpAllocation] {
        return query.apply(store.list())
    }
}
