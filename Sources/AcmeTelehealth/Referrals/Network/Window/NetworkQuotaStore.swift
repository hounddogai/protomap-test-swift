import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps network quotas by code.
    protocol NetworkQuotaStore {
        func find(_ code: String) -> NetworkQuota?
        func save(_ item: NetworkQuota)
        func remove(_ code: String) -> Bool
        func list() -> [NetworkQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryNetworkQuotaStore: NetworkQuotaStore {
        var items: [String: NetworkQuota]
        var order: [String]

        init(items: [String: NetworkQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> NetworkQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: NetworkQuota) {
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

        func list() -> [NetworkQuota] {
            var out: [NetworkQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryNetworkQuotaStore() -> any NetworkQuotaStore {
        return MemoryNetworkQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedNetworkQuotaStore: NetworkQuotaStore {
        var inner: MemoryNetworkQuotaStore
        var cache: TTLCache<NetworkQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryNetworkQuotaStore, cache: TTLCache<NetworkQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> NetworkQuota? {
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

        func save(_ item: NetworkQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [NetworkQuota] {
            return inner.list()
        }
    }

    static func newCachedNetworkQuotaStore(_ inner: MemoryNetworkQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any NetworkQuotaStore {
        return CachedNetworkQuotaStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects network quotas. Empty fields match all.
    final class NetworkQuotaQuery {
        var source: String
        var minRetries: Int
        var statuses: [String]
        var limit: Int

        init(source: String, minRetries: Int, statuses: [String], limit: Int) {
            self.source = source
            self.minRetries = minRetries
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: NetworkQuota) -> Bool {
            if source != "" && (Kit.Text.normalize(item.source) != Kit.Text.normalize(source)) {
                return false
            }
            if item.retries < minRetries {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [NetworkQuota]) -> [NetworkQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: NetworkQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findNetworkQuotas(_ store: any NetworkQuotaStore, query: NetworkQuotaQuery) -> [NetworkQuota] {
        return query.apply(store.list())
    }
}
