import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps fallback authorization claims by code.
    protocol FallbackAuthorizationClaimStore {
        func find(_ code: String) -> FallbackAuthorizationClaim?
        func save(_ item: FallbackAuthorizationClaim)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackAuthorizationClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackAuthorizationClaimStore: FallbackAuthorizationClaimStore {
        var items: [String: FallbackAuthorizationClaim]
        var order: [String]

        init(items: [String: FallbackAuthorizationClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackAuthorizationClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackAuthorizationClaim) {
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

        func list() -> [FallbackAuthorizationClaim] {
            var out: [FallbackAuthorizationClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackAuthorizationClaimStore() -> any FallbackAuthorizationClaimStore {
        return MemoryFallbackAuthorizationClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackAuthorizationClaimStore: FallbackAuthorizationClaimStore {
        var inner: MemoryFallbackAuthorizationClaimStore
        var cache: TTLCache<FallbackAuthorizationClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackAuthorizationClaimStore, cache: TTLCache<FallbackAuthorizationClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackAuthorizationClaim? {
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

        func save(_ item: FallbackAuthorizationClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackAuthorizationClaim] {
            return inner.list()
        }
    }

    static func newCachedFallbackAuthorizationClaimStore(_ inner: MemoryFallbackAuthorizationClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackAuthorizationClaimStore {
        return CachedFallbackAuthorizationClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback authorization claims. Empty fields match all.
    final class FallbackAuthorizationClaimQuery {
        var title: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackAuthorizationClaim) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [FallbackAuthorizationClaim]) -> [FallbackAuthorizationClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackAuthorizationClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackAuthorizationClaims(_ store: any FallbackAuthorizationClaimStore, query: FallbackAuthorizationClaimQuery) -> [FallbackAuthorizationClaim] {
        return query.apply(store.list())
    }
}
