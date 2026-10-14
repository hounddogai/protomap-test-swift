import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps read allocations by code.
    protocol ReadAllocationStore {
        func find(_ code: String) -> ReadAllocation?
        func save(_ item: ReadAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [ReadAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReadAllocationStore: ReadAllocationStore {
        var items: [String: ReadAllocation]
        var order: [String]

        init(items: [String: ReadAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReadAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReadAllocation) {
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

        func list() -> [ReadAllocation] {
            var out: [ReadAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReadAllocationStore() -> any ReadAllocationStore {
        return MemoryReadAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReadAllocationStore: ReadAllocationStore {
        var inner: MemoryReadAllocationStore
        var cache: TTLCache<ReadAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryReadAllocationStore, cache: TTLCache<ReadAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReadAllocation? {
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

        func save(_ item: ReadAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReadAllocation] {
            return inner.list()
        }
    }

    static func newCachedReadAllocationStore(_ inner: MemoryReadAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReadAllocationStore {
        return CachedReadAllocationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects read allocations. Empty fields match all.
    final class ReadAllocationQuery {
        var country: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReadAllocation) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [ReadAllocation]) -> [ReadAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReadAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReadAllocations(_ store: any ReadAllocationStore, query: ReadAllocationQuery) -> [ReadAllocation] {
        return query.apply(store.list())
    }
}
