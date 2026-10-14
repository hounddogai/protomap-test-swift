import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps handoff slots by code.
    protocol HandoffSlotStore {
        func find(_ code: String) -> HandoffSlot?
        func save(_ item: HandoffSlot)
        func remove(_ code: String) -> Bool
        func list() -> [HandoffSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryHandoffSlotStore: HandoffSlotStore {
        var items: [String: HandoffSlot]
        var order: [String]

        init(items: [String: HandoffSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> HandoffSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: HandoffSlot) {
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

        func list() -> [HandoffSlot] {
            var out: [HandoffSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryHandoffSlotStore() -> any HandoffSlotStore {
        return MemoryHandoffSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedHandoffSlotStore: HandoffSlotStore {
        var inner: MemoryHandoffSlotStore
        var cache: TTLCache<HandoffSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryHandoffSlotStore, cache: TTLCache<HandoffSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> HandoffSlot? {
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

        func save(_ item: HandoffSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [HandoffSlot] {
            return inner.list()
        }
    }

    static func newCachedHandoffSlotStore(_ inner: MemoryHandoffSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any HandoffSlotStore {
        return CachedHandoffSlotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects handoff slots. Empty fields match all.
    final class HandoffSlotQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: HandoffSlot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [HandoffSlot]) -> [HandoffSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: HandoffSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findHandoffSlots(_ store: any HandoffSlotStore, query: HandoffSlotQuery) -> [HandoffSlot] {
        return query.apply(store.list())
    }
}
