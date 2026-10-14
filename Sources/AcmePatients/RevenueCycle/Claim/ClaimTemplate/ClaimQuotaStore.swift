import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim quotas by code.
    protocol ClaimQuotaStore {
        func find(_ code: String) -> ClaimQuota?
        func save(_ item: ClaimQuota)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimQuotaStore: ClaimQuotaStore {
        var items: [String: ClaimQuota]
        var order: [String]

        init(items: [String: ClaimQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimQuota) {
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

        func list() -> [ClaimQuota] {
            var out: [ClaimQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimQuotaStore() -> any ClaimQuotaStore {
        return MemoryClaimQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimQuotaStore: ClaimQuotaStore {
        var inner: MemoryClaimQuotaStore
        var cache: TTLCache<ClaimQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimQuotaStore, cache: TTLCache<ClaimQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimQuota? {
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

        func save(_ item: ClaimQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimQuota] {
            return inner.list()
        }
    }

    static func newCachedClaimQuotaStore(_ inner: MemoryClaimQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimQuotaStore {
        return CachedClaimQuotaStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim quotas. Empty fields match all.
    final class ClaimQuotaQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimQuota) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ClaimQuota]) -> [ClaimQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimQuotas(_ store: any ClaimQuotaStore, query: ClaimQuotaQuery) -> [ClaimQuota] {
        return query.apply(store.list())
    }
}
