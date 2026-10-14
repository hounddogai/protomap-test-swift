import AcmePlatform
import Foundation

extension Labs {
    /// Keeps panel slots by code.
    protocol PanelSlotStore {
        func find(_ code: String) -> PanelSlot?
        func save(_ item: PanelSlot)
        func remove(_ code: String) -> Bool
        func list() -> [PanelSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPanelSlotStore: PanelSlotStore {
        var items: [String: PanelSlot]
        var order: [String]

        init(items: [String: PanelSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PanelSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PanelSlot) {
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

        func list() -> [PanelSlot] {
            var out: [PanelSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPanelSlotStore() -> any PanelSlotStore {
        return MemoryPanelSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPanelSlotStore: PanelSlotStore {
        var inner: MemoryPanelSlotStore
        var cache: TTLCache<PanelSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPanelSlotStore, cache: TTLCache<PanelSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PanelSlot? {
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

        func save(_ item: PanelSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PanelSlot] {
            return inner.list()
        }
    }

    static func newCachedPanelSlotStore(_ inner: MemoryPanelSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PanelSlotStore {
        return CachedPanelSlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects panel slots. Empty fields match all.
    final class PanelSlotQuery {
        var unit: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PanelSlot) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [PanelSlot]) -> [PanelSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PanelSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPanelSlots(_ store: any PanelSlotStore, query: PanelSlotQuery) -> [PanelSlot] {
        return query.apply(store.list())
    }
}
