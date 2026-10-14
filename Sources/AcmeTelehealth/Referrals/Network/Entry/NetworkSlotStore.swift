import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network slots by code.
    protocol NetworkSlotStore {
        func find(_ code: String) -> NetworkSlot?
        func save(_ item: NetworkSlot)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkSlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkSlotStore: NetworkSlotStore {
        var items: [String: NetworkSlot]
        var order: [String]

        init(items: [String: NetworkSlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkSlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkSlot) {
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

        func list() -> [NetworkSlot] {
            var out: [NetworkSlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkSlotStore() -> any NetworkSlotStore {
        return MemoryNetworkSlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkSlotStore: NetworkSlotStore {
        var inner: MemoryNetworkSlotStore
        var cache: TTLCache<NetworkSlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkSlotStore, cache: TTLCache<NetworkSlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkSlot? {
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

        func save(_ item: NetworkSlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkSlot] {
            return inner.list()
        }
    }

    static func newCachedNetworkSlotStore(_ inner: MemoryNetworkSlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkSlotStore {
        return CachedNetworkSlotStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network slots. Empty fields match all.
    final class NetworkSlotQuery {
        var label: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkSlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [NetworkSlot]) -> [NetworkSlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkSlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkSlots(_ store: any NetworkSlotStore, query: NetworkSlotQuery) -> [NetworkSlot] {
        return query.apply(store.list())
    }
}
