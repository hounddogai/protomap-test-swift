import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps global outreach allocations by code.
    protocol GlobalOutreachAllocationStore {
        func find(_ code: String) -> GlobalOutreachAllocation?
        func save(_ item: GlobalOutreachAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalOutreachAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalOutreachAllocationStore: GlobalOutreachAllocationStore {
        var items: [String: GlobalOutreachAllocation]
        var order: [String]

        init(items: [String: GlobalOutreachAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalOutreachAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalOutreachAllocation) {
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

        func list() -> [GlobalOutreachAllocation] {
            var out: [GlobalOutreachAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalOutreachAllocationStore() -> any GlobalOutreachAllocationStore {
        return MemoryGlobalOutreachAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalOutreachAllocationStore: GlobalOutreachAllocationStore {
        var inner: MemoryGlobalOutreachAllocationStore
        var cache: TTLCache<GlobalOutreachAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalOutreachAllocationStore, cache: TTLCache<GlobalOutreachAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalOutreachAllocation? {
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

        func save(_ item: GlobalOutreachAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalOutreachAllocation] {
            return inner.list()
        }
    }

    static func newCachedGlobalOutreachAllocationStore(_ inner: MemoryGlobalOutreachAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalOutreachAllocationStore {
        return CachedGlobalOutreachAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global outreach allocations. Empty fields match all.
    final class GlobalOutreachAllocationQuery {
        var region: String
        var minLimit: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minLimit: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minLimit = minLimit
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalOutreachAllocation) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.limit < minLimit {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalOutreachAllocation]) -> [GlobalOutreachAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalOutreachAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalOutreachAllocations(_ store: any GlobalOutreachAllocationStore, query: GlobalOutreachAllocationQuery) -> [GlobalOutreachAllocation] {
        return query.apply(store.list())
    }
}
