import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps fallback care protocol profiles by code.
    protocol FallbackCareProtocolProfileStore {
        func find(_ code: String) -> FallbackCareProtocolProfile?
        func save(_ item: FallbackCareProtocolProfile)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackCareProtocolProfile]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackCareProtocolProfileStore: FallbackCareProtocolProfileStore {
        var items: [String: FallbackCareProtocolProfile]
        var order: [String]

        init(items: [String: FallbackCareProtocolProfile], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackCareProtocolProfile? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackCareProtocolProfile) {
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

        func list() -> [FallbackCareProtocolProfile] {
            var out: [FallbackCareProtocolProfile] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackCareProtocolProfileStore() -> any FallbackCareProtocolProfileStore {
        return MemoryFallbackCareProtocolProfileStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackCareProtocolProfileStore: FallbackCareProtocolProfileStore {
        var inner: MemoryFallbackCareProtocolProfileStore
        var cache: TTLCache<FallbackCareProtocolProfile>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackCareProtocolProfileStore, cache: TTLCache<FallbackCareProtocolProfile>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackCareProtocolProfile? {
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

        func save(_ item: FallbackCareProtocolProfile) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackCareProtocolProfile] {
            return inner.list()
        }
    }

    static func newCachedFallbackCareProtocolProfileStore(_ inner: MemoryFallbackCareProtocolProfileStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackCareProtocolProfileStore {
        return CachedFallbackCareProtocolProfileStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback care protocol profiles. Empty fields match all.
    final class FallbackCareProtocolProfileQuery {
        var region: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minAmount: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackCareProtocolProfile) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackCareProtocolProfile]) -> [FallbackCareProtocolProfile] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackCareProtocolProfile) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackCareProtocolProfiles(_ store: any FallbackCareProtocolProfileStore, query: FallbackCareProtocolProfileQuery) -> [FallbackCareProtocolProfile] {
        return query.apply(store.list())
    }
}
