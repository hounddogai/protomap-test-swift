import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps default charge claims by code.
    protocol DefaultChargeClaimStore {
        func find(_ code: String) -> DefaultChargeClaim?
        func save(_ item: DefaultChargeClaim)
        func remove(_ code: String) -> Bool
        func list() -> [DefaultChargeClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryDefaultChargeClaimStore: DefaultChargeClaimStore {
        var items: [String: DefaultChargeClaim]
        var order: [String]

        init(items: [String: DefaultChargeClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> DefaultChargeClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: DefaultChargeClaim) {
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

        func list() -> [DefaultChargeClaim] {
            var out: [DefaultChargeClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryDefaultChargeClaimStore() -> any DefaultChargeClaimStore {
        return MemoryDefaultChargeClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedDefaultChargeClaimStore: DefaultChargeClaimStore {
        var inner: MemoryDefaultChargeClaimStore
        var cache: TTLCache<DefaultChargeClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryDefaultChargeClaimStore, cache: TTLCache<DefaultChargeClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> DefaultChargeClaim? {
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

        func save(_ item: DefaultChargeClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [DefaultChargeClaim] {
            return inner.list()
        }
    }

    static func newCachedDefaultChargeClaimStore(_ inner: MemoryDefaultChargeClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any DefaultChargeClaimStore {
        return CachedDefaultChargeClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects default charge claims. Empty fields match all.
    final class DefaultChargeClaimQuery {
        var name: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: DefaultChargeClaim) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [DefaultChargeClaim]) -> [DefaultChargeClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: DefaultChargeClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findDefaultChargeClaims(_ store: any DefaultChargeClaimStore, query: DefaultChargeClaimQuery) -> [DefaultChargeClaim] {
        return query.apply(store.list())
    }
}
