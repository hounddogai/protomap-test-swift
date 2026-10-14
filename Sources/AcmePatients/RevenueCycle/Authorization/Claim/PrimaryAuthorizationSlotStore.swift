import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps primary authorization slots by code.
    protocol PrimaryAuthorizationSlotStore {
        func find(_ code: String) -> PrimaryAuthorizationSlot?
        func save(_ item: PrimaryAuthorizationSlot)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryAuthorizationSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryAuthorizationSlotStore: PrimaryAuthorizationSlotStore {
        var items: [String: PrimaryAuthorizationSlot]
        var order: [String]

        init(items: [String: PrimaryAuthorizationSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryAuthorizationSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryAuthorizationSlot) {
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

        func list() -> [PrimaryAuthorizationSlot] {
            var out: [PrimaryAuthorizationSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryAuthorizationSlotStore() -> any PrimaryAuthorizationSlotStore {
        return MemoryPrimaryAuthorizationSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryAuthorizationSlotStore: PrimaryAuthorizationSlotStore {
        var inner: MemoryPrimaryAuthorizationSlotStore
        var cache: TTLCache<PrimaryAuthorizationSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryAuthorizationSlotStore, cache: TTLCache<PrimaryAuthorizationSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryAuthorizationSlot? {
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

        func save(_ item: PrimaryAuthorizationSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryAuthorizationSlot] {
            return inner.list()
        }
    }

    static func newCachedPrimaryAuthorizationSlotStore(_ inner: MemoryPrimaryAuthorizationSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryAuthorizationSlotStore {
        return CachedPrimaryAuthorizationSlotStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary authorization slots. Empty fields match all.
    final class PrimaryAuthorizationSlotQuery {
        var unit: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryAuthorizationSlot) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.durationMinutes < minDurationMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryAuthorizationSlot]) -> [PrimaryAuthorizationSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryAuthorizationSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryAuthorizationSlots(_ store: any PrimaryAuthorizationSlotStore, query: PrimaryAuthorizationSlotQuery) -> [PrimaryAuthorizationSlot] {
        return query.apply(store.list())
    }
}
