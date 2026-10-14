import AcmePlatform
import Foundation

extension BedManagement {
    /// Keeps rolling cleaning slots by code.
    protocol RollingCleaningSlotStore {
        func find(_ code: String) -> RollingCleaningSlot?
        func save(_ item: RollingCleaningSlot)
        func remove(_ code: String) -> Bool
        func list() -> [RollingCleaningSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRollingCleaningSlotStore: RollingCleaningSlotStore {
        var items: [String: RollingCleaningSlot]
        var order: [String]

        init(items: [String: RollingCleaningSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RollingCleaningSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RollingCleaningSlot) {
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

        func list() -> [RollingCleaningSlot] {
            var out: [RollingCleaningSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRollingCleaningSlotStore() -> any RollingCleaningSlotStore {
        return MemoryRollingCleaningSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRollingCleaningSlotStore: RollingCleaningSlotStore {
        var inner: MemoryRollingCleaningSlotStore
        var cache: TTLCache<RollingCleaningSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryRollingCleaningSlotStore, cache: TTLCache<RollingCleaningSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RollingCleaningSlot? {
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

        func save(_ item: RollingCleaningSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RollingCleaningSlot] {
            return inner.list()
        }
    }

    static func newCachedRollingCleaningSlotStore(_ inner: MemoryRollingCleaningSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RollingCleaningSlotStore {
        return CachedRollingCleaningSlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects rolling cleaning slots. Empty fields match all.
    final class RollingCleaningSlotQuery {
        var facility: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(facility: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.facility = facility
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RollingCleaningSlot) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RollingCleaningSlot]) -> [RollingCleaningSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RollingCleaningSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRollingCleaningSlots(_ store: any RollingCleaningSlotStore, query: RollingCleaningSlotQuery) -> [RollingCleaningSlot] {
        return query.apply(store.list())
    }
}
