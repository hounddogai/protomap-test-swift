import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps denial tiers by code.
    protocol DenialTierStore {
        func find(_ code: String) -> DenialTier?
        func save(_ item: DenialTier)
        func remove(_ code: String) -> Bool
        func list() -> [DenialTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDenialTierStore: DenialTierStore {
        var items: [String: DenialTier]
        var order: [String]

        init(items: [String: DenialTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DenialTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DenialTier) {
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

        func list() -> [DenialTier] {
            var out: [DenialTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDenialTierStore() -> any DenialTierStore {
        return MemoryDenialTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDenialTierStore: DenialTierStore {
        var inner: MemoryDenialTierStore
        var cache: TTLCache<DenialTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryDenialTierStore, cache: TTLCache<DenialTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DenialTier? {
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

        func save(_ item: DenialTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DenialTier] {
            return inner.list()
        }
    }

    static func newCachedDenialTierStore(_ inner: MemoryDenialTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DenialTierStore {
        return CachedDenialTierStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects denial tiers. Empty fields match all.
    final class DenialTierQuery {
        var unit: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(unit: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.unit = unit
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DenialTier) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [DenialTier]) -> [DenialTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DenialTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDenialTiers(_ store: any DenialTierStore, query: DenialTierQuery) -> [DenialTier] {
        return query.apply(store.list())
    }
}
