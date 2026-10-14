import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps charge quotas by code.
    protocol ChargeQuotaStore {
        func find(_ code: String) -> ChargeQuota?
        func save(_ item: ChargeQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ChargeQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryChargeQuotaStore: ChargeQuotaStore {
        var items: [String: ChargeQuota]
        var order: [String]

        init(items: [String: ChargeQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ChargeQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ChargeQuota) {
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

        func list() -> [ChargeQuota] {
            var out: [ChargeQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryChargeQuotaStore() -> any ChargeQuotaStore {
        return MemoryChargeQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedChargeQuotaStore: ChargeQuotaStore {
        var inner: MemoryChargeQuotaStore
        var cache: TTLCache<ChargeQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryChargeQuotaStore, cache: TTLCache<ChargeQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ChargeQuota? {
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

        func save(_ item: ChargeQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ChargeQuota] {
            return inner.list()
        }
    }

    static func newCachedChargeQuotaStore(_ inner: MemoryChargeQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ChargeQuotaStore {
        return CachedChargeQuotaStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects charge quotas. Empty fields match all.
    final class ChargeQuotaQuery {
        var region: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(region: String, minRate: Double, statuses: [String], limit: Int) {
            self.region = region
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ChargeQuota) -> Bool {
            if region != "" && (Kit.Text.normalize(item.region) != Kit.Text.normalize(region)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ChargeQuota]) -> [ChargeQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ChargeQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findChargeQuotas(_ store: any ChargeQuotaStore, query: ChargeQuotaQuery) -> [ChargeQuota] {
        return query.apply(store.list())
    }
}
