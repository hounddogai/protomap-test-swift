import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps lenient discharge plan slots by code.
    protocol LenientDischargePlanSlotStore {
        func find(_ code: String) -> LenientDischargePlanSlot?
        func save(_ item: LenientDischargePlanSlot)
        func remove(_ code: String) -> Bool
        func list() -> [LenientDischargePlanSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientDischargePlanSlotStore: LenientDischargePlanSlotStore {
        var items: [String: LenientDischargePlanSlot]
        var order: [String]

        init(items: [String: LenientDischargePlanSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientDischargePlanSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientDischargePlanSlot) {
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

        func list() -> [LenientDischargePlanSlot] {
            var out: [LenientDischargePlanSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientDischargePlanSlotStore() -> any LenientDischargePlanSlotStore {
        return MemoryLenientDischargePlanSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientDischargePlanSlotStore: LenientDischargePlanSlotStore {
        var inner: MemoryLenientDischargePlanSlotStore
        var cache: TTLCache<LenientDischargePlanSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientDischargePlanSlotStore, cache: TTLCache<LenientDischargePlanSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientDischargePlanSlot? {
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

        func save(_ item: LenientDischargePlanSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientDischargePlanSlot] {
            return inner.list()
        }
    }

    static func newCachedLenientDischargePlanSlotStore(_ inner: MemoryLenientDischargePlanSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientDischargePlanSlotStore {
        return CachedLenientDischargePlanSlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient discharge plan slots. Empty fields match all.
    final class LenientDischargePlanSlotQuery {
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

        func matches(_ item: LenientDischargePlanSlot) -> Bool {
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

        func apply(_ items: [LenientDischargePlanSlot]) -> [LenientDischargePlanSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientDischargePlanSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientDischargePlanSlots(_ store: any LenientDischargePlanSlotStore, query: LenientDischargePlanSlotQuery) -> [LenientDischargePlanSlot] {
        return query.apply(store.list())
    }
}
