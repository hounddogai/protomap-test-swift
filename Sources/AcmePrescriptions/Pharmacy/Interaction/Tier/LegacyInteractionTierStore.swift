import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps legacy interaction tiers by code.
    protocol LegacyInteractionTierStore {
        func find(_ code: String) -> LegacyInteractionTier?
        func save(_ item: LegacyInteractionTier)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyInteractionTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyInteractionTierStore: LegacyInteractionTierStore {
        var items: [String: LegacyInteractionTier]
        var order: [String]

        init(items: [String: LegacyInteractionTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyInteractionTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyInteractionTier) {
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

        func list() -> [LegacyInteractionTier] {
            var out: [LegacyInteractionTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyInteractionTierStore() -> any LegacyInteractionTierStore {
        return MemoryLegacyInteractionTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyInteractionTierStore: LegacyInteractionTierStore {
        var inner: MemoryLegacyInteractionTierStore
        var cache: TTLCache<LegacyInteractionTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyInteractionTierStore, cache: TTLCache<LegacyInteractionTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyInteractionTier? {
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

        func save(_ item: LegacyInteractionTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyInteractionTier] {
            return inner.list()
        }
    }

    static func newCachedLegacyInteractionTierStore(_ inner: MemoryLegacyInteractionTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyInteractionTierStore {
        return CachedLegacyInteractionTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy interaction tiers. Empty fields match all.
    final class LegacyInteractionTierQuery {
        var name: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyInteractionTier) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LegacyInteractionTier]) -> [LegacyInteractionTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyInteractionTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyInteractionTiers(_ store: any LegacyInteractionTierStore, query: LegacyInteractionTierQuery) -> [LegacyInteractionTier] {
        return query.apply(store.list())
    }
}
