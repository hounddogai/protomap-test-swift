import AcmePlatform
import Foundation

extension Labs {
    /// Keeps courier slots by code.
    protocol CourierSlotStore {
        func find(_ code: String) -> CourierSlot?
        func save(_ item: CourierSlot)
        func remove(_ code: String) -> Bool
        func list() -> [CourierSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCourierSlotStore: CourierSlotStore {
        var items: [String: CourierSlot]
        var order: [String]

        init(items: [String: CourierSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CourierSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CourierSlot) {
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

        func list() -> [CourierSlot] {
            var out: [CourierSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCourierSlotStore() -> any CourierSlotStore {
        return MemoryCourierSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCourierSlotStore: CourierSlotStore {
        var inner: MemoryCourierSlotStore
        var cache: TTLCache<CourierSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryCourierSlotStore, cache: TTLCache<CourierSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CourierSlot? {
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

        func save(_ item: CourierSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CourierSlot] {
            return inner.list()
        }
    }

    static func newCachedCourierSlotStore(_ inner: MemoryCourierSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CourierSlotStore {
        return CachedCourierSlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects courier slots. Empty fields match all.
    final class CourierSlotQuery {
        var segment: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CourierSlot) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CourierSlot]) -> [CourierSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CourierSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCourierSlots(_ store: any CourierSlotStore, query: CourierSlotQuery) -> [CourierSlot] {
        return query.apply(store.list())
    }
}
