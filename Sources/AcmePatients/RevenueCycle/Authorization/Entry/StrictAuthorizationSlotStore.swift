import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps strict authorization slots by code.
    protocol StrictAuthorizationSlotStore {
        func find(_ code: String) -> StrictAuthorizationSlot?
        func save(_ item: StrictAuthorizationSlot)
        func remove(_ code: String) -> Bool
        func list() -> [StrictAuthorizationSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictAuthorizationSlotStore: StrictAuthorizationSlotStore {
        var items: [String: StrictAuthorizationSlot]
        var order: [String]

        init(items: [String: StrictAuthorizationSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictAuthorizationSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictAuthorizationSlot) {
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

        func list() -> [StrictAuthorizationSlot] {
            var out: [StrictAuthorizationSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictAuthorizationSlotStore() -> any StrictAuthorizationSlotStore {
        return MemoryStrictAuthorizationSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictAuthorizationSlotStore: StrictAuthorizationSlotStore {
        var inner: MemoryStrictAuthorizationSlotStore
        var cache: TTLCache<StrictAuthorizationSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictAuthorizationSlotStore, cache: TTLCache<StrictAuthorizationSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictAuthorizationSlot? {
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

        func save(_ item: StrictAuthorizationSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictAuthorizationSlot] {
            return inner.list()
        }
    }

    static func newCachedStrictAuthorizationSlotStore(_ inner: MemoryStrictAuthorizationSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictAuthorizationSlotStore {
        return CachedStrictAuthorizationSlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict authorization slots. Empty fields match all.
    final class StrictAuthorizationSlotQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictAuthorizationSlot) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [StrictAuthorizationSlot]) -> [StrictAuthorizationSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictAuthorizationSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictAuthorizationSlots(_ store: any StrictAuthorizationSlotStore, query: StrictAuthorizationSlotQuery) -> [StrictAuthorizationSlot] {
        return query.apply(store.list())
    }
}
