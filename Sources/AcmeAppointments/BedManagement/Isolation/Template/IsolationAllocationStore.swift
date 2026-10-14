import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps isolation allocations by code.
    protocol IsolationAllocationStore {
        func find(_ code: String) -> IsolationAllocation?
        func save(_ item: IsolationAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [IsolationAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryIsolationAllocationStore: IsolationAllocationStore {
        var items: [String: IsolationAllocation]
        var order: [String]

        init(items: [String: IsolationAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> IsolationAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: IsolationAllocation) {
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

        func list() -> [IsolationAllocation] {
            var out: [IsolationAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryIsolationAllocationStore() -> any IsolationAllocationStore {
        return MemoryIsolationAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedIsolationAllocationStore: IsolationAllocationStore {
        var inner: MemoryIsolationAllocationStore
        var cache: TTLCache<IsolationAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryIsolationAllocationStore, cache: TTLCache<IsolationAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> IsolationAllocation? {
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

        func save(_ item: IsolationAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [IsolationAllocation] {
            return inner.list()
        }
    }

    static func newCachedIsolationAllocationStore(_ inner: MemoryIsolationAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any IsolationAllocationStore {
        return CachedIsolationAllocationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects isolation allocations. Empty fields match all.
    final class IsolationAllocationQuery {
        var locale: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: IsolationAllocation) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [IsolationAllocation]) -> [IsolationAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: IsolationAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findIsolationAllocations(_ store: any IsolationAllocationStore, query: IsolationAllocationQuery) -> [IsolationAllocation] {
        return query.apply(store.list())
    }
}
