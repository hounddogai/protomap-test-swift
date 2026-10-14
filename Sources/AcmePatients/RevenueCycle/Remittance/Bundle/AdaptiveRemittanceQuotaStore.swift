import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps adaptive remittance quotas by code.
    protocol AdaptiveRemittanceQuotaStore {
        func find(_ code: String) -> AdaptiveRemittanceQuota?
        func save(_ item: AdaptiveRemittanceQuota)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveRemittanceQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveRemittanceQuotaStore: AdaptiveRemittanceQuotaStore {
        var items: [String: AdaptiveRemittanceQuota]
        var order: [String]

        init(items: [String: AdaptiveRemittanceQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveRemittanceQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveRemittanceQuota) {
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

        func list() -> [AdaptiveRemittanceQuota] {
            var out: [AdaptiveRemittanceQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveRemittanceQuotaStore() -> any AdaptiveRemittanceQuotaStore {
        return MemoryAdaptiveRemittanceQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveRemittanceQuotaStore: AdaptiveRemittanceQuotaStore {
        var inner: MemoryAdaptiveRemittanceQuotaStore
        var cache: TTLCache<AdaptiveRemittanceQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveRemittanceQuotaStore, cache: TTLCache<AdaptiveRemittanceQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveRemittanceQuota? {
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

        func save(_ item: AdaptiveRemittanceQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveRemittanceQuota] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveRemittanceQuotaStore(_ inner: MemoryAdaptiveRemittanceQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveRemittanceQuotaStore {
        return CachedAdaptiveRemittanceQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive remittance quotas. Empty fields match all.
    final class AdaptiveRemittanceQuotaQuery {
        var segment: String
        var minWeight: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minWeight: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minWeight = minWeight
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveRemittanceQuota) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.weight < minWeight {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveRemittanceQuota]) -> [AdaptiveRemittanceQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveRemittanceQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveRemittanceQuotas(_ store: any AdaptiveRemittanceQuotaStore, query: AdaptiveRemittanceQuotaQuery) -> [AdaptiveRemittanceQuota] {
        return query.apply(store.list())
    }
}
