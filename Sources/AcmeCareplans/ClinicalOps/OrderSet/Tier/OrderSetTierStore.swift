import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps order set tiers by code.
    protocol OrderSetTierStore {
        func find(_ code: String) -> OrderSetTier?
        func save(_ item: OrderSetTier)
        func remove(_ code: String) -> Bool
        func list() -> [OrderSetTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryOrderSetTierStore: OrderSetTierStore {
        var items: [String: OrderSetTier]
        var order: [String]

        init(items: [String: OrderSetTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> OrderSetTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: OrderSetTier) {
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

        func list() -> [OrderSetTier] {
            var out: [OrderSetTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryOrderSetTierStore() -> any OrderSetTierStore {
        return MemoryOrderSetTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedOrderSetTierStore: OrderSetTierStore {
        var inner: MemoryOrderSetTierStore
        var cache: TTLCache<OrderSetTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryOrderSetTierStore, cache: TTLCache<OrderSetTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> OrderSetTier? {
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

        func save(_ item: OrderSetTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [OrderSetTier] {
            return inner.list()
        }
    }

    static func newCachedOrderSetTierStore(_ inner: MemoryOrderSetTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any OrderSetTierStore {
        return CachedOrderSetTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects order set tiers. Empty fields match all.
    final class OrderSetTierQuery {
        var label: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: OrderSetTier) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [OrderSetTier]) -> [OrderSetTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: OrderSetTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findOrderSetTiers(_ store: any OrderSetTierStore, query: OrderSetTierQuery) -> [OrderSetTier] {
        return query.apply(store.list())
    }
}
