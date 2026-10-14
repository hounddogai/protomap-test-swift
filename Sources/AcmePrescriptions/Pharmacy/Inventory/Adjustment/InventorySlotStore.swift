import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory slots by code.
    protocol InventorySlotStore {
        func find(_ code: String) -> InventorySlot?
        func save(_ item: InventorySlot)
        func remove(_ code: String) -> Bool
        func list() -> [InventorySlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventorySlotStore: InventorySlotStore {
        var items: [String: InventorySlot]
        var order: [String]

        init(items: [String: InventorySlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventorySlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventorySlot) {
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

        func list() -> [InventorySlot] {
            var out: [InventorySlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventorySlotStore() -> any InventorySlotStore {
        return MemoryInventorySlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventorySlotStore: InventorySlotStore {
        var inner: MemoryInventorySlotStore
        var cache: TTLCache<InventorySlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventorySlotStore, cache: TTLCache<InventorySlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventorySlot? {
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

        func save(_ item: InventorySlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventorySlot] {
            return inner.list()
        }
    }

    static func newCachedInventorySlotStore(_ inner: MemoryInventorySlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventorySlotStore {
        return CachedInventorySlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory slots. Empty fields match all.
    final class InventorySlotQuery {
        var channel: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventorySlot) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventorySlot]) -> [InventorySlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventorySlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventorySlots(_ store: any InventorySlotStore, query: InventorySlotQuery) -> [InventorySlot] {
        return query.apply(store.list())
    }
}
