import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps weighted claim overrides by code.
    protocol WeightedClaimOverrideStore {
        func find(_ code: String) -> WeightedClaimOverride?
        func save(_ item: WeightedClaimOverride)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedClaimOverride]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedClaimOverrideStore: WeightedClaimOverrideStore {
        var items: [String: WeightedClaimOverride]
        var order: [String]

        init(items: [String: WeightedClaimOverride], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedClaimOverride? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedClaimOverride) {
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

        func list() -> [WeightedClaimOverride] {
            var out: [WeightedClaimOverride] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedClaimOverrideStore() -> any WeightedClaimOverrideStore {
        return MemoryWeightedClaimOverrideStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedClaimOverrideStore: WeightedClaimOverrideStore {
        var inner: MemoryWeightedClaimOverrideStore
        var cache: TTLCache<WeightedClaimOverride>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedClaimOverrideStore, cache: TTLCache<WeightedClaimOverride>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedClaimOverride? {
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

        func save(_ item: WeightedClaimOverride) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedClaimOverride] {
            return inner.list()
        }
    }

    static func newCachedWeightedClaimOverrideStore(_ inner: MemoryWeightedClaimOverrideStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedClaimOverrideStore {
        return CachedWeightedClaimOverrideStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted claim overrides. Empty fields match all.
    final class WeightedClaimOverrideQuery {
        var country: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedClaimOverride) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.batchSize < minBatchSize {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedClaimOverride]) -> [WeightedClaimOverride] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedClaimOverride) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedClaimOverrides(_ store: any WeightedClaimOverrideStore, query: WeightedClaimOverrideQuery) -> [WeightedClaimOverride] {
        return query.apply(store.list())
    }
}
