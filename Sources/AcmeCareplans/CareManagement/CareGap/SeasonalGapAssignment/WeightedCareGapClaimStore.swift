import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps weighted care gap claims by code.
    protocol WeightedCareGapClaimStore {
        func find(_ code: String) -> WeightedCareGapClaim?
        func save(_ item: WeightedCareGapClaim)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedCareGapClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedCareGapClaimStore: WeightedCareGapClaimStore {
        var items: [String: WeightedCareGapClaim]
        var order: [String]

        init(items: [String: WeightedCareGapClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedCareGapClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedCareGapClaim) {
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

        func list() -> [WeightedCareGapClaim] {
            var out: [WeightedCareGapClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedCareGapClaimStore() -> any WeightedCareGapClaimStore {
        return MemoryWeightedCareGapClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedCareGapClaimStore: WeightedCareGapClaimStore {
        var inner: MemoryWeightedCareGapClaimStore
        var cache: TTLCache<WeightedCareGapClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedCareGapClaimStore, cache: TTLCache<WeightedCareGapClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedCareGapClaim? {
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

        func save(_ item: WeightedCareGapClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedCareGapClaim] {
            return inner.list()
        }
    }

    static func newCachedWeightedCareGapClaimStore(_ inner: MemoryWeightedCareGapClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedCareGapClaimStore {
        return CachedWeightedCareGapClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted care gap claims. Empty fields match all.
    final class WeightedCareGapClaimQuery {
        var region: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(region: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.region = region
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedCareGapClaim) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
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

        func apply(_ items: [WeightedCareGapClaim]) -> [WeightedCareGapClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedCareGapClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedCareGapClaims(_ store: any WeightedCareGapClaimStore, query: WeightedCareGapClaimQuery) -> [WeightedCareGapClaim] {
        return query.apply(store.list())
    }
}
