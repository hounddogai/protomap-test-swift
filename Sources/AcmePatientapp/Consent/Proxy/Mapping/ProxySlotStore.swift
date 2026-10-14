import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy slots by code.
    protocol ProxySlotStore {
        func find(_ code: String) -> ProxySlot?
        func save(_ item: ProxySlot)
        func remove(_ code: String) -> Bool
        func list() -> [ProxySlot]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxySlotStore: ProxySlotStore {
        var items: [String: ProxySlot]
        var order: [String]

        init(items: [String: ProxySlot], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxySlot? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxySlot) {
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

        func list() -> [ProxySlot] {
            var out: [ProxySlot] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxySlotStore() -> any ProxySlotStore {
        return MemoryProxySlotStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxySlotStore: ProxySlotStore {
        var inner: MemoryProxySlotStore
        var cache: TTLCache<ProxySlot>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxySlotStore, cache: TTLCache<ProxySlot>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxySlot? {
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

        func save(_ item: ProxySlot) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxySlot] {
            return inner.list()
        }
    }

    static func newCachedProxySlotStore(_ inner: MemoryProxySlotStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxySlotStore {
        return CachedProxySlotStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy slots. Empty fields match all.
    final class ProxySlotQuery {
        var label: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxySlot) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxySlot]) -> [ProxySlot] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxySlot) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxySlots(_ store: any ProxySlotStore, query: ProxySlotQuery) -> [ProxySlot] {
        return query.apply(store.list())
    }
}
