import AcmePlatform
import Foundation

extension Labs {
    /// Keeps fallback specimen tiers by code.
    protocol FallbackSpecimenTierStore {
        func find(_ code: String) -> FallbackSpecimenTier?
        func save(_ item: FallbackSpecimenTier)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackSpecimenTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackSpecimenTierStore: FallbackSpecimenTierStore {
        var items: [String: FallbackSpecimenTier]
        var order: [String]

        init(items: [String: FallbackSpecimenTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackSpecimenTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackSpecimenTier) {
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

        func list() -> [FallbackSpecimenTier] {
            var out: [FallbackSpecimenTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackSpecimenTierStore() -> any FallbackSpecimenTierStore {
        return MemoryFallbackSpecimenTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackSpecimenTierStore: FallbackSpecimenTierStore {
        var inner: MemoryFallbackSpecimenTierStore
        var cache: TTLCache<FallbackSpecimenTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackSpecimenTierStore, cache: TTLCache<FallbackSpecimenTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackSpecimenTier? {
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

        func save(_ item: FallbackSpecimenTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackSpecimenTier] {
            return inner.list()
        }
    }

    static func newCachedFallbackSpecimenTierStore(_ inner: MemoryFallbackSpecimenTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackSpecimenTierStore {
        return CachedFallbackSpecimenTierStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback specimen tiers. Empty fields match all.
    final class FallbackSpecimenTierQuery {
        var facility: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackSpecimenTier) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackSpecimenTier]) -> [FallbackSpecimenTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackSpecimenTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackSpecimenTiers(_ store: any FallbackSpecimenTierStore, query: FallbackSpecimenTierQuery) -> [FallbackSpecimenTier] {
        return query.apply(store.list())
    }
}
