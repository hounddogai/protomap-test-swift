import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy allocations by code.
    protocol ProxyAllocationStore {
        func find(_ code: String) -> ProxyAllocation?
        func save(_ item: ProxyAllocation)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyAllocation]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyAllocationStore: ProxyAllocationStore {
        var items: [String: ProxyAllocation]
        var order: [String]

        init(items: [String: ProxyAllocation], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyAllocation? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyAllocation) {
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

        func list() -> [ProxyAllocation] {
            var out: [ProxyAllocation] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyAllocationStore() -> any ProxyAllocationStore {
        return MemoryProxyAllocationStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyAllocationStore: ProxyAllocationStore {
        var inner: MemoryProxyAllocationStore
        var cache: TTLCache<ProxyAllocation>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyAllocationStore, cache: TTLCache<ProxyAllocation>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyAllocation? {
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

        func save(_ item: ProxyAllocation) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyAllocation] {
            return inner.list()
        }
    }

    static func newCachedProxyAllocationStore(_ inner: MemoryProxyAllocationStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyAllocationStore {
        return CachedProxyAllocationStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy allocations. Empty fields match all.
    final class ProxyAllocationQuery {
        var channel: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyAllocation) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [ProxyAllocation]) -> [ProxyAllocation] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyAllocation) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyAllocations(_ store: any ProxyAllocationStore, query: ProxyAllocationQuery) -> [ProxyAllocation] {
        return query.apply(store.list())
    }
}
