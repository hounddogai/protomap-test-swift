import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps strict care protocol tiers by code.
    protocol StrictCareProtocolTierStore {
        func find(_ code: String) -> StrictCareProtocolTier?
        func save(_ item: StrictCareProtocolTier)
        func remove(_ code: String) -> Bool
        func list() -> [StrictCareProtocolTier]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictCareProtocolTierStore: StrictCareProtocolTierStore {
        var items: [String: StrictCareProtocolTier]
        var order: [String]

        init(items: [String: StrictCareProtocolTier], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictCareProtocolTier? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictCareProtocolTier) {
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

        func list() -> [StrictCareProtocolTier] {
            var out: [StrictCareProtocolTier] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictCareProtocolTierStore() -> any StrictCareProtocolTierStore {
        return MemoryStrictCareProtocolTierStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictCareProtocolTierStore: StrictCareProtocolTierStore {
        var inner: MemoryStrictCareProtocolTierStore
        var cache: TTLCache<StrictCareProtocolTier>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictCareProtocolTierStore, cache: TTLCache<StrictCareProtocolTier>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictCareProtocolTier? {
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

        func save(_ item: StrictCareProtocolTier) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictCareProtocolTier] {
            return inner.list()
        }
    }

    static func newCachedStrictCareProtocolTierStore(_ inner: MemoryStrictCareProtocolTierStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictCareProtocolTierStore {
        return CachedStrictCareProtocolTierStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict care protocol tiers. Empty fields match all.
    final class StrictCareProtocolTierQuery {
        var facility: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(facility: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.facility = facility
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictCareProtocolTier) -> Bool {
            if facility != "" && (Kit.Text.normalize(item.facility) != Kit.Text.normalize(facility)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StrictCareProtocolTier]) -> [StrictCareProtocolTier] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictCareProtocolTier) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictCareProtocolTiers(_ store: any StrictCareProtocolTierStore, query: StrictCareProtocolTierQuery) -> [StrictCareProtocolTier] {
        return query.apply(store.list())
    }
}
