import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps interaction slots by code.
    protocol InteractionSlotStore {
        func find(_ code: String) -> InteractionSlot?
        func save(_ item: InteractionSlot)
        func remove(_ code: String) -> Bool
        func list() -> [InteractionSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInteractionSlotStore: InteractionSlotStore {
        var items: [String: InteractionSlot]
        var order: [String]

        init(items: [String: InteractionSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InteractionSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InteractionSlot) {
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

        func list() -> [InteractionSlot] {
            var out: [InteractionSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInteractionSlotStore() -> any InteractionSlotStore {
        return MemoryInteractionSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInteractionSlotStore: InteractionSlotStore {
        var inner: MemoryInteractionSlotStore
        var cache: TTLCache<InteractionSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryInteractionSlotStore, cache: TTLCache<InteractionSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InteractionSlot? {
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

        func save(_ item: InteractionSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InteractionSlot] {
            return inner.list()
        }
    }

    static func newCachedInteractionSlotStore(_ inner: MemoryInteractionSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InteractionSlotStore {
        return CachedInteractionSlotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects interaction slots. Empty fields match all.
    final class InteractionSlotQuery {
        var unit: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InteractionSlot) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InteractionSlot]) -> [InteractionSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InteractionSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInteractionSlots(_ store: any InteractionSlotStore, query: InteractionSlotQuery) -> [InteractionSlot] {
        return query.apply(store.list())
    }
}
