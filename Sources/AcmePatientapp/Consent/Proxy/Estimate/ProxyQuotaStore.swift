import AcmePlatform
import Foundation

extension Consent {
    /// Keeps proxy quotas by code.
    protocol ProxyQuotaStore {
        func find(_ code: String) -> ProxyQuota?
        func save(_ item: ProxyQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ProxyQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryProxyQuotaStore: ProxyQuotaStore {
        var items: [String: ProxyQuota]
        var order: [String]

        init(items: [String: ProxyQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ProxyQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ProxyQuota) {
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

        func list() -> [ProxyQuota] {
            var out: [ProxyQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryProxyQuotaStore() -> any ProxyQuotaStore {
        return MemoryProxyQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedProxyQuotaStore: ProxyQuotaStore {
        var inner: MemoryProxyQuotaStore
        var cache: TTLCache<ProxyQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryProxyQuotaStore, cache: TTLCache<ProxyQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ProxyQuota? {
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

        func save(_ item: ProxyQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ProxyQuota] {
            return inner.list()
        }
    }

    static func newCachedProxyQuotaStore(_ inner: MemoryProxyQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ProxyQuotaStore {
        return CachedProxyQuotaStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects proxy quotas. Empty fields match all.
    final class ProxyQuotaQuery {
        var segment: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(segment: String, minRefills: Int, statuses: [String], limit: Int) {
            self.segment = segment
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ProxyQuota) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ProxyQuota]) -> [ProxyQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ProxyQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findProxyQuotas(_ store: any ProxyQuotaStore, query: ProxyQuotaQuery) -> [ProxyQuota] {
        return query.apply(store.list())
    }
}
