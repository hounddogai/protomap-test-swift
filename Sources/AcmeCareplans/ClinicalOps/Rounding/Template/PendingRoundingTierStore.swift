import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps pending rounding tiers by code.
    protocol PendingRoundingTierStore {
        func find(_ code: String) -> PendingRoundingTier?
        func save(_ item: PendingRoundingTier)
        func remove(_ code: String) -> Bool
        func list() -> [PendingRoundingTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingRoundingTierStore: PendingRoundingTierStore {
        var items: [String: PendingRoundingTier]
        var order: [String]

        init(items: [String: PendingRoundingTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingRoundingTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingRoundingTier) {
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

        func list() -> [PendingRoundingTier] {
            var out: [PendingRoundingTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingRoundingTierStore() -> any PendingRoundingTierStore {
        return MemoryPendingRoundingTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingRoundingTierStore: PendingRoundingTierStore {
        var inner: MemoryPendingRoundingTierStore
        var cache: TTLCache<PendingRoundingTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingRoundingTierStore, cache: TTLCache<PendingRoundingTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingRoundingTier? {
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

        func save(_ item: PendingRoundingTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingRoundingTier] {
            return inner.list()
        }
    }

    static func newCachedPendingRoundingTierStore(_ inner: MemoryPendingRoundingTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingRoundingTierStore {
        return CachedPendingRoundingTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending rounding tiers. Empty fields match all.
    final class PendingRoundingTierQuery {
        var country: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingRoundingTier) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [PendingRoundingTier]) -> [PendingRoundingTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingRoundingTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingRoundingTiers(_ store: any PendingRoundingTierStore, query: PendingRoundingTierQuery) -> [PendingRoundingTier] {
        return query.apply(store.list())
    }
}
