import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps regional care protocol quotas by code.
    protocol RegionalCareProtocolQuotaStore {
        func find(_ code: String) -> RegionalCareProtocolQuota?
        func save(_ item: RegionalCareProtocolQuota)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalCareProtocolQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalCareProtocolQuotaStore: RegionalCareProtocolQuotaStore {
        var items: [String: RegionalCareProtocolQuota]
        var order: [String]

        init(items: [String: RegionalCareProtocolQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalCareProtocolQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalCareProtocolQuota) {
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

        func list() -> [RegionalCareProtocolQuota] {
            var out: [RegionalCareProtocolQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalCareProtocolQuotaStore() -> any RegionalCareProtocolQuotaStore {
        return MemoryRegionalCareProtocolQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalCareProtocolQuotaStore: RegionalCareProtocolQuotaStore {
        var inner: MemoryRegionalCareProtocolQuotaStore
        var cache: TTLCache<RegionalCareProtocolQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalCareProtocolQuotaStore, cache: TTLCache<RegionalCareProtocolQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalCareProtocolQuota? {
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

        func save(_ item: RegionalCareProtocolQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalCareProtocolQuota] {
            return inner.list()
        }
    }

    static func newCachedRegionalCareProtocolQuotaStore(_ inner: MemoryRegionalCareProtocolQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalCareProtocolQuotaStore {
        return CachedRegionalCareProtocolQuotaStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional care protocol quotas. Empty fields match all.
    final class RegionalCareProtocolQuotaQuery {
        var channel: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalCareProtocolQuota) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalCareProtocolQuota]) -> [RegionalCareProtocolQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalCareProtocolQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalCareProtocolQuotas(_ store: any RegionalCareProtocolQuotaStore, query: RegionalCareProtocolQuotaQuery) -> [RegionalCareProtocolQuota] {
        return query.apply(store.list())
    }
}
