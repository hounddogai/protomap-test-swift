import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory policies by code.
    protocol InventoryPolicyStore {
        func find(_ code: String) -> InventoryPolicy?
        func save(_ item: InventoryPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryPolicyStore: InventoryPolicyStore {
        var items: [String: InventoryPolicy]
        var order: [String]

        init(items: [String: InventoryPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryPolicy) {
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

        func list() -> [InventoryPolicy] {
            var out: [InventoryPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryPolicyStore() -> any InventoryPolicyStore {
        return MemoryInventoryPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryPolicyStore: InventoryPolicyStore {
        var inner: MemoryInventoryPolicyStore
        var cache: TTLCache<InventoryPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryPolicyStore, cache: TTLCache<InventoryPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryPolicy? {
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

        func save(_ item: InventoryPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryPolicy] {
            return inner.list()
        }
    }

    static func newCachedInventoryPolicyStore(_ inner: MemoryInventoryPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryPolicyStore {
        return CachedInventoryPolicyStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory policies. Empty fields match all.
    final class InventoryPolicyQuery {
        var channel: String
        var minDurationMinutes: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minDurationMinutes: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minDurationMinutes = minDurationMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryPolicy) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
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

        func apply(_ items: [InventoryPolicy]) -> [InventoryPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryPolicies(_ store: any InventoryPolicyStore, query: InventoryPolicyQuery) -> [InventoryPolicy] {
        return query.apply(store.list())
    }
}
