import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps fallback goal claims by code.
    protocol FallbackGoalClaimStore {
        func find(_ code: String) -> FallbackGoalClaim?
        func save(_ item: FallbackGoalClaim)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackGoalClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackGoalClaimStore: FallbackGoalClaimStore {
        var items: [String: FallbackGoalClaim]
        var order: [String]

        init(items: [String: FallbackGoalClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackGoalClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackGoalClaim) {
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

        func list() -> [FallbackGoalClaim] {
            var out: [FallbackGoalClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackGoalClaimStore() -> any FallbackGoalClaimStore {
        return MemoryFallbackGoalClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackGoalClaimStore: FallbackGoalClaimStore {
        var inner: MemoryFallbackGoalClaimStore
        var cache: TTLCache<FallbackGoalClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackGoalClaimStore, cache: TTLCache<FallbackGoalClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackGoalClaim? {
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

        func save(_ item: FallbackGoalClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackGoalClaim] {
            return inner.list()
        }
    }

    static func newCachedFallbackGoalClaimStore(_ inner: MemoryFallbackGoalClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackGoalClaimStore {
        return CachedFallbackGoalClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback goal claims. Empty fields match all.
    final class FallbackGoalClaimQuery {
        var region: String
        var minAcuity: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minAcuity: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minAcuity = minAcuity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackGoalClaim) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.acuity < minAcuity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackGoalClaim]) -> [FallbackGoalClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackGoalClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackGoalClaims(_ store: any FallbackGoalClaimStore, query: FallbackGoalClaimQuery) -> [FallbackGoalClaim] {
        return query.apply(store.list())
    }
}
