import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted network quotas by code.
    protocol WeightedNetworkQuotaStore {
        func find(_ code: String) -> WeightedNetworkQuota?
        func save(_ item: WeightedNetworkQuota)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedNetworkQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedNetworkQuotaStore: WeightedNetworkQuotaStore {
        var items: [String: WeightedNetworkQuota]
        var order: [String]

        init(items: [String: WeightedNetworkQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedNetworkQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedNetworkQuota) {
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

        func list() -> [WeightedNetworkQuota] {
            var out: [WeightedNetworkQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedNetworkQuotaStore() -> any WeightedNetworkQuotaStore {
        return MemoryWeightedNetworkQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedNetworkQuotaStore: WeightedNetworkQuotaStore {
        var inner: MemoryWeightedNetworkQuotaStore
        var cache: TTLCache<WeightedNetworkQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedNetworkQuotaStore, cache: TTLCache<WeightedNetworkQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedNetworkQuota? {
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

        func save(_ item: WeightedNetworkQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedNetworkQuota] {
            return inner.list()
        }
    }

    static func newCachedWeightedNetworkQuotaStore(_ inner: MemoryWeightedNetworkQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedNetworkQuotaStore {
        return CachedWeightedNetworkQuotaStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted network quotas. Empty fields match all.
    final class WeightedNetworkQuotaQuery {
        var name: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedNetworkQuota) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedNetworkQuota]) -> [WeightedNetworkQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedNetworkQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedNetworkQuotas(_ store: any WeightedNetworkQuotaStore, query: WeightedNetworkQuotaQuery) -> [WeightedNetworkQuota] {
        return query.apply(store.list())
    }
}
