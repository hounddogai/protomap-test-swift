import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps pending charge quotas by code.
    protocol PendingChargeQuotaStore {
        func find(_ code: String) -> PendingChargeQuota?
        func save(_ item: PendingChargeQuota)
        func remove(_ code: String) -> Bool
        func list() -> [PendingChargeQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingChargeQuotaStore: PendingChargeQuotaStore {
        var items: [String: PendingChargeQuota]
        var order: [String]

        init(items: [String: PendingChargeQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingChargeQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingChargeQuota) {
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

        func list() -> [PendingChargeQuota] {
            var out: [PendingChargeQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingChargeQuotaStore() -> any PendingChargeQuotaStore {
        return MemoryPendingChargeQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingChargeQuotaStore: PendingChargeQuotaStore {
        var inner: MemoryPendingChargeQuotaStore
        var cache: TTLCache<PendingChargeQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingChargeQuotaStore, cache: TTLCache<PendingChargeQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingChargeQuota? {
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

        func save(_ item: PendingChargeQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingChargeQuota] {
            return inner.list()
        }
    }

    static func newCachedPendingChargeQuotaStore(_ inner: MemoryPendingChargeQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingChargeQuotaStore {
        return CachedPendingChargeQuotaStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending charge quotas. Empty fields match all.
    final class PendingChargeQuotaQuery {
        var category: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingChargeQuota) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingChargeQuota]) -> [PendingChargeQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingChargeQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingChargeQuotas(_ store: any PendingChargeQuotaStore, query: PendingChargeQuotaQuery) -> [PendingChargeQuota] {
        return query.apply(store.list())
    }
}
