import AcmePlatform
import Foundation

extension Staffing {
    /// Keeps float pool allocations by code.
    protocol FloatPoolAllocationStore {
        func find(_ code: String) -> FloatPoolAllocation?
        func save(_ item: FloatPoolAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [FloatPoolAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFloatPoolAllocationStore: FloatPoolAllocationStore {
        var items: [String: FloatPoolAllocation]
        var order: [String]

        init(items: [String: FloatPoolAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FloatPoolAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FloatPoolAllocation) {
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

        func list() -> [FloatPoolAllocation] {
            var out: [FloatPoolAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFloatPoolAllocationStore() -> any FloatPoolAllocationStore {
        return MemoryFloatPoolAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFloatPoolAllocationStore: FloatPoolAllocationStore {
        var inner: MemoryFloatPoolAllocationStore
        var cache: TTLCache<FloatPoolAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryFloatPoolAllocationStore, cache: TTLCache<FloatPoolAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FloatPoolAllocation? {
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

        func save(_ item: FloatPoolAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FloatPoolAllocation] {
            return inner.list()
        }
    }

    static func newCachedFloatPoolAllocationStore(_ inner: MemoryFloatPoolAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FloatPoolAllocationStore {
        return CachedFloatPoolAllocationStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects float pool allocations. Empty fields match all.
    final class FloatPoolAllocationQuery {
        var ward: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMargin: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FloatPoolAllocation) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FloatPoolAllocation]) -> [FloatPoolAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FloatPoolAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFloatPoolAllocations(_ store: any FloatPoolAllocationStore, query: FloatPoolAllocationQuery) -> [FloatPoolAllocation] {
        return query.apply(store.list())
    }
}
