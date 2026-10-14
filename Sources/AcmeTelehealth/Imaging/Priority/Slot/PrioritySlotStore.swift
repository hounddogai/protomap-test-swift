import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority slots by code.
    protocol PrioritySlotStore {
        func find(_ code: String) -> PrioritySlot?
        func save(_ item: PrioritySlot)
        func remove(_ code: String) -> Bool
        func list() -> [PrioritySlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrioritySlotStore: PrioritySlotStore {
        var items: [String: PrioritySlot]
        var order: [String]

        init(items: [String: PrioritySlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrioritySlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrioritySlot) {
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

        func list() -> [PrioritySlot] {
            var out: [PrioritySlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrioritySlotStore() -> any PrioritySlotStore {
        return MemoryPrioritySlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrioritySlotStore: PrioritySlotStore {
        var inner: MemoryPrioritySlotStore
        var cache: TTLCache<PrioritySlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrioritySlotStore, cache: TTLCache<PrioritySlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrioritySlot? {
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

        func save(_ item: PrioritySlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrioritySlot] {
            return inner.list()
        }
    }

    static func newCachedPrioritySlotStore(_ inner: MemoryPrioritySlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrioritySlotStore {
        return CachedPrioritySlotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority slots. Empty fields match all.
    final class PrioritySlotQuery {
        var region: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minAmount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrioritySlot) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrioritySlot]) -> [PrioritySlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrioritySlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrioritySlots(_ store: any PrioritySlotStore, query: PrioritySlotQuery) -> [PrioritySlot] {
        return query.apply(store.list())
    }
}
