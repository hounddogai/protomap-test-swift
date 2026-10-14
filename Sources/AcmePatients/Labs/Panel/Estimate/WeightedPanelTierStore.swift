import AcmePlatform
import Foundation

extension Labs {
    /// Keeps weighted panel tiers by code.
    protocol WeightedPanelTierStore {
        func find(_ code: String) -> WeightedPanelTier?
        func save(_ item: WeightedPanelTier)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedPanelTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedPanelTierStore: WeightedPanelTierStore {
        var items: [String: WeightedPanelTier]
        var order: [String]

        init(items: [String: WeightedPanelTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedPanelTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedPanelTier) {
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

        func list() -> [WeightedPanelTier] {
            var out: [WeightedPanelTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedPanelTierStore() -> any WeightedPanelTierStore {
        return MemoryWeightedPanelTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedPanelTierStore: WeightedPanelTierStore {
        var inner: MemoryWeightedPanelTierStore
        var cache: TTLCache<WeightedPanelTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedPanelTierStore, cache: TTLCache<WeightedPanelTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedPanelTier? {
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

        func save(_ item: WeightedPanelTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedPanelTier] {
            return inner.list()
        }
    }

    static func newCachedWeightedPanelTierStore(_ inner: MemoryWeightedPanelTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedPanelTierStore {
        return CachedWeightedPanelTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted panel tiers. Empty fields match all.
    final class WeightedPanelTierQuery {
        var region: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minSequence: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedPanelTier) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedPanelTier]) -> [WeightedPanelTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedPanelTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedPanelTiers(_ store: any WeightedPanelTierStore, query: WeightedPanelTierQuery) -> [WeightedPanelTier] {
        return query.apply(store.list())
    }
}
