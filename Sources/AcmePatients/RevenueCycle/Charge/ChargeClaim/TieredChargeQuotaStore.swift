import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps tiered charge quotas by code.
    protocol TieredChargeQuotaStore {
        func find(_ code: String) -> TieredChargeQuota?
        func save(_ item: TieredChargeQuota)
        func remove(_ code: String) -> Bool
        func list() -> [TieredChargeQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredChargeQuotaStore: TieredChargeQuotaStore {
        var items: [String: TieredChargeQuota]
        var order: [String]

        init(items: [String: TieredChargeQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredChargeQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredChargeQuota) {
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

        func list() -> [TieredChargeQuota] {
            var out: [TieredChargeQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredChargeQuotaStore() -> any TieredChargeQuotaStore {
        return MemoryTieredChargeQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredChargeQuotaStore: TieredChargeQuotaStore {
        var inner: MemoryTieredChargeQuotaStore
        var cache: TTLCache<TieredChargeQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredChargeQuotaStore, cache: TTLCache<TieredChargeQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredChargeQuota? {
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

        func save(_ item: TieredChargeQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredChargeQuota] {
            return inner.list()
        }
    }

    static func newCachedTieredChargeQuotaStore(_ inner: MemoryTieredChargeQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredChargeQuotaStore {
        return CachedTieredChargeQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered charge quotas. Empty fields match all.
    final class TieredChargeQuotaQuery {
        var label: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(label: String, minRate: Double, statuses: [String], limit: Int) {
            self.label = label
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredChargeQuota) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [TieredChargeQuota]) -> [TieredChargeQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredChargeQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredChargeQuotas(_ store: any TieredChargeQuotaStore, query: TieredChargeQuotaQuery) -> [TieredChargeQuota] {
        return query.apply(store.list())
    }
}
