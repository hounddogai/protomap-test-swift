import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps inventory tiers by code.
    protocol InventoryTierStore {
        func find(_ code: String) -> InventoryTier?
        func save(_ item: InventoryTier)
        func remove(_ code: String) -> Bool
        func list() -> [InventoryTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryInventoryTierStore: InventoryTierStore {
        var items: [String: InventoryTier]
        var order: [String]

        init(items: [String: InventoryTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> InventoryTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: InventoryTier) {
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

        func list() -> [InventoryTier] {
            var out: [InventoryTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryInventoryTierStore() -> any InventoryTierStore {
        return MemoryInventoryTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedInventoryTierStore: InventoryTierStore {
        var inner: MemoryInventoryTierStore
        var cache: TTLCache<InventoryTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryInventoryTierStore, cache: TTLCache<InventoryTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> InventoryTier? {
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

        func save(_ item: InventoryTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [InventoryTier] {
            return inner.list()
        }
    }

    static func newCachedInventoryTierStore(_ inner: MemoryInventoryTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any InventoryTierStore {
        return CachedInventoryTierStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects inventory tiers. Empty fields match all.
    final class InventoryTierQuery {
        var segment: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: InventoryTier) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [InventoryTier]) -> [InventoryTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: InventoryTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findInventoryTiers(_ store: any InventoryTierStore, query: InventoryTierQuery) -> [InventoryTier] {
        return query.apply(store.list())
    }
}
