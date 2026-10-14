import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps primary overtime allocations by code.
    protocol PrimaryOvertimeAllocationStore {
        func find(_ code: String) -> PrimaryOvertimeAllocation?
        func save(_ item: PrimaryOvertimeAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryOvertimeAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryOvertimeAllocationStore: PrimaryOvertimeAllocationStore {
        var items: [String: PrimaryOvertimeAllocation]
        var order: [String]

        init(items: [String: PrimaryOvertimeAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryOvertimeAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryOvertimeAllocation) {
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

        func list() -> [PrimaryOvertimeAllocation] {
            var out: [PrimaryOvertimeAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryOvertimeAllocationStore() -> any PrimaryOvertimeAllocationStore {
        return MemoryPrimaryOvertimeAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryOvertimeAllocationStore: PrimaryOvertimeAllocationStore {
        var inner: MemoryPrimaryOvertimeAllocationStore
        var cache: TTLCache<PrimaryOvertimeAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryOvertimeAllocationStore, cache: TTLCache<PrimaryOvertimeAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryOvertimeAllocation? {
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

        func save(_ item: PrimaryOvertimeAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryOvertimeAllocation] {
            return inner.list()
        }
    }

    static func newCachedPrimaryOvertimeAllocationStore(_ inner: MemoryPrimaryOvertimeAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryOvertimeAllocationStore {
        return CachedPrimaryOvertimeAllocationStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary overtime allocations. Empty fields match all.
    final class PrimaryOvertimeAllocationQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryOvertimeAllocation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryOvertimeAllocation]) -> [PrimaryOvertimeAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryOvertimeAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryOvertimeAllocations(_ store: any PrimaryOvertimeAllocationStore, query: PrimaryOvertimeAllocationQuery) -> [PrimaryOvertimeAllocation] {
        return query.apply(store.list())
    }
}
