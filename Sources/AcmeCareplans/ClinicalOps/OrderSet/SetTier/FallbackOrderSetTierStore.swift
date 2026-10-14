import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps fallback order set tiers by code.
    protocol FallbackOrderSetTierStore {
        func find(_ code: String) -> FallbackOrderSetTier?
        func save(_ item: FallbackOrderSetTier)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackOrderSetTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackOrderSetTierStore: FallbackOrderSetTierStore {
        var items: [String: FallbackOrderSetTier]
        var order: [String]

        init(items: [String: FallbackOrderSetTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackOrderSetTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackOrderSetTier) {
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

        func list() -> [FallbackOrderSetTier] {
            var out: [FallbackOrderSetTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackOrderSetTierStore() -> any FallbackOrderSetTierStore {
        return MemoryFallbackOrderSetTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackOrderSetTierStore: FallbackOrderSetTierStore {
        var inner: MemoryFallbackOrderSetTierStore
        var cache: TTLCache<FallbackOrderSetTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackOrderSetTierStore, cache: TTLCache<FallbackOrderSetTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackOrderSetTier? {
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

        func save(_ item: FallbackOrderSetTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackOrderSetTier] {
            return inner.list()
        }
    }

    static func newCachedFallbackOrderSetTierStore(_ inner: MemoryFallbackOrderSetTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackOrderSetTierStore {
        return CachedFallbackOrderSetTierStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback order set tiers. Empty fields match all.
    final class FallbackOrderSetTierQuery {
        var country: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackOrderSetTier) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
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

        func apply(_ items: [FallbackOrderSetTier]) -> [FallbackOrderSetTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackOrderSetTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackOrderSetTiers(_ store: any FallbackOrderSetTierStore, query: FallbackOrderSetTierQuery) -> [FallbackOrderSetTier] {
        return query.apply(store.list())
    }
}
