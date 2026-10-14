import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge slots by code.
    protocol ChargeSlotStore {
        func find(_ code: String) -> ChargeSlot?
        func save(_ item: ChargeSlot)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeSlotStore: ChargeSlotStore {
        var items: [String: ChargeSlot]
        var order: [String]

        init(items: [String: ChargeSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeSlot) {
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

        func list() -> [ChargeSlot] {
            var out: [ChargeSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeSlotStore() -> any ChargeSlotStore {
        return MemoryChargeSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeSlotStore: ChargeSlotStore {
        var inner: MemoryChargeSlotStore
        var cache: TTLCache<ChargeSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeSlotStore, cache: TTLCache<ChargeSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeSlot? {
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

        func save(_ item: ChargeSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeSlot] {
            return inner.list()
        }
    }

    static func newCachedChargeSlotStore(_ inner: MemoryChargeSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeSlotStore {
        return CachedChargeSlotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge slots. Empty fields match all.
    final class ChargeSlotQuery {
        var label: String
        var minBudget: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minBudget: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minBudget = minBudget
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeSlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.budget < minBudget {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeSlot]) -> [ChargeSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeSlots(_ store: any ChargeSlotStore, query: ChargeSlotQuery) -> [ChargeSlot] {
        return query.apply(store.list())
    }
}
