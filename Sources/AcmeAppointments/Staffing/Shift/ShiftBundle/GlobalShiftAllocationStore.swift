import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps global shift allocations by code.
    protocol GlobalShiftAllocationStore {
        func find(_ code: String) -> GlobalShiftAllocation?
        func save(_ item: GlobalShiftAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalShiftAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalShiftAllocationStore: GlobalShiftAllocationStore {
        var items: [String: GlobalShiftAllocation]
        var order: [String]

        init(items: [String: GlobalShiftAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalShiftAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalShiftAllocation) {
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

        func list() -> [GlobalShiftAllocation] {
            var out: [GlobalShiftAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalShiftAllocationStore() -> any GlobalShiftAllocationStore {
        return MemoryGlobalShiftAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalShiftAllocationStore: GlobalShiftAllocationStore {
        var inner: MemoryGlobalShiftAllocationStore
        var cache: TTLCache<GlobalShiftAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalShiftAllocationStore, cache: TTLCache<GlobalShiftAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalShiftAllocation? {
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

        func save(_ item: GlobalShiftAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalShiftAllocation] {
            return inner.list()
        }
    }

    static func newCachedGlobalShiftAllocationStore(_ inner: MemoryGlobalShiftAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalShiftAllocationStore {
        return CachedGlobalShiftAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global shift allocations. Empty fields match all.
    final class GlobalShiftAllocationQuery {
        var category: String
        var minRevision: Int
        var statuses: [String]
        var limit: Int

        init(category: String, minRevision: Int, statuses: [String], limit: Int) {
            self.category = category
            self.minRevision = minRevision
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalShiftAllocation) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.revision < minRevision {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalShiftAllocation]) -> [GlobalShiftAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalShiftAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalShiftAllocations(_ store: any GlobalShiftAllocationStore, query: GlobalShiftAllocationQuery) -> [GlobalShiftAllocation] {
        return query.apply(store.list())
    }
}
