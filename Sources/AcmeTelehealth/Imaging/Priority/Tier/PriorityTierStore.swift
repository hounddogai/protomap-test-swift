import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps priority tiers by code.
    protocol PriorityTierStore {
        func find(_ code: String) -> PriorityTier?
        func save(_ item: PriorityTier)
        func remove(_ code: String) -> Bool
        func list() -> [PriorityTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPriorityTierStore: PriorityTierStore {
        var items: [String: PriorityTier]
        var order: [String]

        init(items: [String: PriorityTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PriorityTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PriorityTier) {
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

        func list() -> [PriorityTier] {
            var out: [PriorityTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPriorityTierStore() -> any PriorityTierStore {
        return MemoryPriorityTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPriorityTierStore: PriorityTierStore {
        var inner: MemoryPriorityTierStore
        var cache: TTLCache<PriorityTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryPriorityTierStore, cache: TTLCache<PriorityTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PriorityTier? {
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

        func save(_ item: PriorityTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PriorityTier] {
            return inner.list()
        }
    }

    static func newCachedPriorityTierStore(_ inner: MemoryPriorityTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PriorityTierStore {
        return CachedPriorityTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects priority tiers. Empty fields match all.
    final class PriorityTierQuery {
        var category: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PriorityTier) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
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

        func apply(_ items: [PriorityTier]) -> [PriorityTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PriorityTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPriorityTiers(_ store: any PriorityTierStore, query: PriorityTierQuery) -> [PriorityTier] {
        return query.apply(store.list())
    }
}
