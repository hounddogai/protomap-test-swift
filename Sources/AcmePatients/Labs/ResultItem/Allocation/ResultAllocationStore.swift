import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result allocations by code.
    protocol ResultAllocationStore {
        func find(_ code: String) -> ResultAllocation?
        func save(_ item: ResultAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [ResultAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultAllocationStore: ResultAllocationStore {
        var items: [String: ResultAllocation]
        var order: [String]

        init(items: [String: ResultAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultAllocation) {
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

        func list() -> [ResultAllocation] {
            var out: [ResultAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultAllocationStore() -> any ResultAllocationStore {
        return MemoryResultAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultAllocationStore: ResultAllocationStore {
        var inner: MemoryResultAllocationStore
        var cache: TTLCache<ResultAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultAllocationStore, cache: TTLCache<ResultAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultAllocation? {
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

        func save(_ item: ResultAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultAllocation] {
            return inner.list()
        }
    }

    static func newCachedResultAllocationStore(_ inner: MemoryResultAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultAllocationStore {
        return CachedResultAllocationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result allocations. Empty fields match all.
    final class ResultAllocationQuery {
        var title: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultAllocation) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultAllocation]) -> [ResultAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultAllocations(_ store: any ResultAllocationStore, query: ResultAllocationQuery) -> [ResultAllocation] {
        return query.apply(store.list())
    }
}
