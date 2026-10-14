import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps scheduled inventory slots by code.
    protocol ScheduledInventorySlotStore {
        func find(_ code: String) -> ScheduledInventorySlot?
        func save(_ item: ScheduledInventorySlot)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledInventorySlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledInventorySlotStore: ScheduledInventorySlotStore {
        var items: [String: ScheduledInventorySlot]
        var order: [String]

        init(items: [String: ScheduledInventorySlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledInventorySlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledInventorySlot) {
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

        func list() -> [ScheduledInventorySlot] {
            var out: [ScheduledInventorySlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledInventorySlotStore() -> any ScheduledInventorySlotStore {
        return MemoryScheduledInventorySlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledInventorySlotStore: ScheduledInventorySlotStore {
        var inner: MemoryScheduledInventorySlotStore
        var cache: TTLCache<ScheduledInventorySlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledInventorySlotStore, cache: TTLCache<ScheduledInventorySlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledInventorySlot? {
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

        func save(_ item: ScheduledInventorySlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledInventorySlot] {
            return inner.list()
        }
    }

    static func newCachedScheduledInventorySlotStore(_ inner: MemoryScheduledInventorySlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledInventorySlotStore {
        return CachedScheduledInventorySlotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled inventory slots. Empty fields match all.
    final class ScheduledInventorySlotQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledInventorySlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledInventorySlot]) -> [ScheduledInventorySlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledInventorySlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledInventorySlots(_ store: any ScheduledInventorySlotStore, query: ScheduledInventorySlotQuery) -> [ScheduledInventorySlot] {
        return query.apply(store.list())
    }
}
