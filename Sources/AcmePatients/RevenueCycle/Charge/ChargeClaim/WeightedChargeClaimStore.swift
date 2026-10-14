import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps weighted charge claims by code.
    protocol WeightedChargeClaimStore {
        func find(_ code: String) -> WeightedChargeClaim?
        func save(_ item: WeightedChargeClaim)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedChargeClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedChargeClaimStore: WeightedChargeClaimStore {
        var items: [String: WeightedChargeClaim]
        var order: [String]

        init(items: [String: WeightedChargeClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedChargeClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedChargeClaim) {
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

        func list() -> [WeightedChargeClaim] {
            var out: [WeightedChargeClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedChargeClaimStore() -> any WeightedChargeClaimStore {
        return MemoryWeightedChargeClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedChargeClaimStore: WeightedChargeClaimStore {
        var inner: MemoryWeightedChargeClaimStore
        var cache: TTLCache<WeightedChargeClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedChargeClaimStore, cache: TTLCache<WeightedChargeClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedChargeClaim? {
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

        func save(_ item: WeightedChargeClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedChargeClaim] {
            return inner.list()
        }
    }

    static func newCachedWeightedChargeClaimStore(_ inner: MemoryWeightedChargeClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedChargeClaimStore {
        return CachedWeightedChargeClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted charge claims. Empty fields match all.
    final class WeightedChargeClaimQuery {
        var name: String
        var minEndsAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minEndsAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minEndsAt = minEndsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedChargeClaim) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.endsAt < minEndsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedChargeClaim]) -> [WeightedChargeClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedChargeClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedChargeClaims(_ store: any WeightedChargeClaimStore, query: WeightedChargeClaimQuery) -> [WeightedChargeClaim] {
        return query.apply(store.list())
    }
}
