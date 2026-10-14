import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps primary eligibility quotas by code.
    protocol PrimaryEligibilityQuotaStore {
        func find(_ code: String) -> PrimaryEligibilityQuota?
        func save(_ item: PrimaryEligibilityQuota)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryEligibilityQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryEligibilityQuotaStore: PrimaryEligibilityQuotaStore {
        var items: [String: PrimaryEligibilityQuota]
        var order: [String]

        init(items: [String: PrimaryEligibilityQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryEligibilityQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryEligibilityQuota) {
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

        func list() -> [PrimaryEligibilityQuota] {
            var out: [PrimaryEligibilityQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryEligibilityQuotaStore() -> any PrimaryEligibilityQuotaStore {
        return MemoryPrimaryEligibilityQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryEligibilityQuotaStore: PrimaryEligibilityQuotaStore {
        var inner: MemoryPrimaryEligibilityQuotaStore
        var cache: TTLCache<PrimaryEligibilityQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryEligibilityQuotaStore, cache: TTLCache<PrimaryEligibilityQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryEligibilityQuota? {
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

        func save(_ item: PrimaryEligibilityQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryEligibilityQuota] {
            return inner.list()
        }
    }

    static func newCachedPrimaryEligibilityQuotaStore(_ inner: MemoryPrimaryEligibilityQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryEligibilityQuotaStore {
        return CachedPrimaryEligibilityQuotaStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary eligibility quotas. Empty fields match all.
    final class PrimaryEligibilityQuotaQuery {
        var label: String
        var minCreatedAt: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minCreatedAt: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minCreatedAt = minCreatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryEligibilityQuota) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.createdAt < minCreatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryEligibilityQuota]) -> [PrimaryEligibilityQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryEligibilityQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryEligibilityQuotas(_ store: any PrimaryEligibilityQuotaStore, query: PrimaryEligibilityQuotaQuery) -> [PrimaryEligibilityQuota] {
        return query.apply(store.list())
    }
}
