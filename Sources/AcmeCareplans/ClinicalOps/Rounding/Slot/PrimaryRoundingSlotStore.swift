import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps primary rounding slots by code.
    protocol PrimaryRoundingSlotStore {
        func find(_ code: String) -> PrimaryRoundingSlot?
        func save(_ item: PrimaryRoundingSlot)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryRoundingSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryRoundingSlotStore: PrimaryRoundingSlotStore {
        var items: [String: PrimaryRoundingSlot]
        var order: [String]

        init(items: [String: PrimaryRoundingSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryRoundingSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryRoundingSlot) {
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

        func list() -> [PrimaryRoundingSlot] {
            var out: [PrimaryRoundingSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryRoundingSlotStore() -> any PrimaryRoundingSlotStore {
        return MemoryPrimaryRoundingSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryRoundingSlotStore: PrimaryRoundingSlotStore {
        var inner: MemoryPrimaryRoundingSlotStore
        var cache: TTLCache<PrimaryRoundingSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryRoundingSlotStore, cache: TTLCache<PrimaryRoundingSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryRoundingSlot? {
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

        func save(_ item: PrimaryRoundingSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryRoundingSlot] {
            return inner.list()
        }
    }

    static func newCachedPrimaryRoundingSlotStore(_ inner: MemoryPrimaryRoundingSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryRoundingSlotStore {
        return CachedPrimaryRoundingSlotStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary rounding slots. Empty fields match all.
    final class PrimaryRoundingSlotQuery {
        var name: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryRoundingSlot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryRoundingSlot]) -> [PrimaryRoundingSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryRoundingSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryRoundingSlots(_ store: any PrimaryRoundingSlotStore, query: PrimaryRoundingSlotQuery) -> [PrimaryRoundingSlot] {
        return query.apply(store.list())
    }
}
