import AcmePlatform
import Foundation

extension Labs {
    /// Keeps global result slots by code.
    protocol GlobalResultSlotStore {
        func find(_ code: String) -> GlobalResultSlot?
        func save(_ item: GlobalResultSlot)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalResultSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalResultSlotStore: GlobalResultSlotStore {
        var items: [String: GlobalResultSlot]
        var order: [String]

        init(items: [String: GlobalResultSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalResultSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalResultSlot) {
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

        func list() -> [GlobalResultSlot] {
            var out: [GlobalResultSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalResultSlotStore() -> any GlobalResultSlotStore {
        return MemoryGlobalResultSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalResultSlotStore: GlobalResultSlotStore {
        var inner: MemoryGlobalResultSlotStore
        var cache: TTLCache<GlobalResultSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalResultSlotStore, cache: TTLCache<GlobalResultSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalResultSlot? {
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

        func save(_ item: GlobalResultSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalResultSlot] {
            return inner.list()
        }
    }

    static func newCachedGlobalResultSlotStore(_ inner: MemoryGlobalResultSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalResultSlotStore {
        return CachedGlobalResultSlotStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global result slots. Empty fields match all.
    final class GlobalResultSlotQuery {
        var name: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalResultSlot) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalResultSlot]) -> [GlobalResultSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalResultSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalResultSlots(_ store: any GlobalResultSlotStore, query: GlobalResultSlotQuery) -> [GlobalResultSlot] {
        return query.apply(store.list())
    }
}
