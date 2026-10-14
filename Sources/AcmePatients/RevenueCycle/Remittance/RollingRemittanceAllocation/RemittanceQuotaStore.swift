import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps remittance quotas by code.
    protocol RemittanceQuotaStore {
        func find(_ code: String) -> RemittanceQuota?
        func save(_ item: RemittanceQuota)
        func remove(_ code: String) -> Bool
        func list() -> [RemittanceQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRemittanceQuotaStore: RemittanceQuotaStore {
        var items: [String: RemittanceQuota]
        var order: [String]

        init(items: [String: RemittanceQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RemittanceQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RemittanceQuota) {
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

        func list() -> [RemittanceQuota] {
            var out: [RemittanceQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRemittanceQuotaStore() -> any RemittanceQuotaStore {
        return MemoryRemittanceQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRemittanceQuotaStore: RemittanceQuotaStore {
        var inner: MemoryRemittanceQuotaStore
        var cache: TTLCache<RemittanceQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryRemittanceQuotaStore, cache: TTLCache<RemittanceQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RemittanceQuota? {
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

        func save(_ item: RemittanceQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RemittanceQuota] {
            return inner.list()
        }
    }

    static func newCachedRemittanceQuotaStore(_ inner: MemoryRemittanceQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RemittanceQuotaStore {
        return CachedRemittanceQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects remittance quotas. Empty fields match all.
    final class RemittanceQuotaQuery {
        var name: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RemittanceQuota) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [RemittanceQuota]) -> [RemittanceQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RemittanceQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRemittanceQuotas(_ store: any RemittanceQuotaStore, query: RemittanceQuotaQuery) -> [RemittanceQuota] {
        return query.apply(store.list())
    }
}
