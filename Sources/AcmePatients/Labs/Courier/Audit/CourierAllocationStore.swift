import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier allocations by code.
    protocol CourierAllocationStore {
        func find(_ code: String) -> CourierAllocation?
        func save(_ item: CourierAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [CourierAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierAllocationStore: CourierAllocationStore {
        var items: [String: CourierAllocation]
        var order: [String]

        init(items: [String: CourierAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierAllocation) {
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

        func list() -> [CourierAllocation] {
            var out: [CourierAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierAllocationStore() -> any CourierAllocationStore {
        return MemoryCourierAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierAllocationStore: CourierAllocationStore {
        var inner: MemoryCourierAllocationStore
        var cache: TTLCache<CourierAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierAllocationStore, cache: TTLCache<CourierAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierAllocation? {
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

        func save(_ item: CourierAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierAllocation] {
            return inner.list()
        }
    }

    static func newCachedCourierAllocationStore(_ inner: MemoryCourierAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierAllocationStore {
        return CachedCourierAllocationStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier allocations. Empty fields match all.
    final class CourierAllocationQuery {
        var segment: String
        var minDosageMg: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minDosageMg: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minDosageMg = minDosageMg
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierAllocation) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.dosageMg < minDosageMg {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierAllocation]) -> [CourierAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierAllocations(_ store: any CourierAllocationStore, query: CourierAllocationQuery) -> [CourierAllocation] {
        return query.apply(store.list())
    }
}
