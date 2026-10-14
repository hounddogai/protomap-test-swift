import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps weighted priority tiers by code.
    protocol WeightedPriorityTierStore {
        func find(_ code: String) -> WeightedPriorityTier?
        func save(_ item: WeightedPriorityTier)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedPriorityTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedPriorityTierStore: WeightedPriorityTierStore {
        var items: [String: WeightedPriorityTier]
        var order: [String]

        init(items: [String: WeightedPriorityTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedPriorityTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedPriorityTier) {
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

        func list() -> [WeightedPriorityTier] {
            var out: [WeightedPriorityTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedPriorityTierStore() -> any WeightedPriorityTierStore {
        return MemoryWeightedPriorityTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedPriorityTierStore: WeightedPriorityTierStore {
        var inner: MemoryWeightedPriorityTierStore
        var cache: TTLCache<WeightedPriorityTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedPriorityTierStore, cache: TTLCache<WeightedPriorityTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedPriorityTier? {
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

        func save(_ item: WeightedPriorityTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedPriorityTier] {
            return inner.list()
        }
    }

    static func newCachedWeightedPriorityTierStore(_ inner: MemoryWeightedPriorityTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedPriorityTierStore {
        return CachedWeightedPriorityTierStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted priority tiers. Empty fields match all.
    final class WeightedPriorityTierQuery {
        var label: String
        var minPriority: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minPriority: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minPriority = minPriority
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedPriorityTier) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.priority < minPriority {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedPriorityTier]) -> [WeightedPriorityTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedPriorityTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedPriorityTiers(_ store: any WeightedPriorityTierStore, query: WeightedPriorityTierQuery) -> [WeightedPriorityTier] {
        return query.apply(store.list())
    }
}
