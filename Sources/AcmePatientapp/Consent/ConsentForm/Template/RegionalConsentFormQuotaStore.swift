import AcmePlatform
import Foundation

extension Consent {
    /// Keeps regional consent form quotas by code.
    protocol RegionalConsentFormQuotaStore {
        func find(_ code: String) -> RegionalConsentFormQuota?
        func save(_ item: RegionalConsentFormQuota)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalConsentFormQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalConsentFormQuotaStore: RegionalConsentFormQuotaStore {
        var items: [String: RegionalConsentFormQuota]
        var order: [String]

        init(items: [String: RegionalConsentFormQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalConsentFormQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalConsentFormQuota) {
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

        func list() -> [RegionalConsentFormQuota] {
            var out: [RegionalConsentFormQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalConsentFormQuotaStore() -> any RegionalConsentFormQuotaStore {
        return MemoryRegionalConsentFormQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalConsentFormQuotaStore: RegionalConsentFormQuotaStore {
        var inner: MemoryRegionalConsentFormQuotaStore
        var cache: TTLCache<RegionalConsentFormQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalConsentFormQuotaStore, cache: TTLCache<RegionalConsentFormQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalConsentFormQuota? {
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

        func save(_ item: RegionalConsentFormQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalConsentFormQuota] {
            return inner.list()
        }
    }

    static func newCachedRegionalConsentFormQuotaStore(_ inner: MemoryRegionalConsentFormQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalConsentFormQuotaStore {
        return CachedRegionalConsentFormQuotaStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional consent form quotas. Empty fields match all.
    final class RegionalConsentFormQuotaQuery {
        var title: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalConsentFormQuota) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalConsentFormQuota]) -> [RegionalConsentFormQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalConsentFormQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalConsentFormQuotas(_ store: any RegionalConsentFormQuotaStore, query: RegionalConsentFormQuotaQuery) -> [RegionalConsentFormQuota] {
        return query.apply(store.list())
    }
}
