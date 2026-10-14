import AcmePlatform
import Foundation

extension Consent {
    /// Keeps fallback revocation tiers by code.
    protocol FallbackRevocationTierStore {
        func find(_ code: String) -> FallbackRevocationTier?
        func save(_ item: FallbackRevocationTier)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackRevocationTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackRevocationTierStore: FallbackRevocationTierStore {
        var items: [String: FallbackRevocationTier]
        var order: [String]

        init(items: [String: FallbackRevocationTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackRevocationTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackRevocationTier) {
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

        func list() -> [FallbackRevocationTier] {
            var out: [FallbackRevocationTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackRevocationTierStore() -> any FallbackRevocationTierStore {
        return MemoryFallbackRevocationTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackRevocationTierStore: FallbackRevocationTierStore {
        var inner: MemoryFallbackRevocationTierStore
        var cache: TTLCache<FallbackRevocationTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackRevocationTierStore, cache: TTLCache<FallbackRevocationTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackRevocationTier? {
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

        func save(_ item: FallbackRevocationTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackRevocationTier] {
            return inner.list()
        }
    }

    static func newCachedFallbackRevocationTierStore(_ inner: MemoryFallbackRevocationTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackRevocationTierStore {
        return CachedFallbackRevocationTierStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback revocation tiers. Empty fields match all.
    final class FallbackRevocationTierQuery {
        var region: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackRevocationTier) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackRevocationTier]) -> [FallbackRevocationTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackRevocationTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackRevocationTiers(_ store: any FallbackRevocationTierStore, query: FallbackRevocationTierQuery) -> [FallbackRevocationTier] {
        return query.apply(store.list())
    }
}
