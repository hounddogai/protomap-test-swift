import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps follow up quotas by code.
    protocol FollowUpQuotaStore {
        func find(_ code: String) -> FollowUpQuota?
        func save(_ item: FollowUpQuota)
        func remove(_ code: String) -> Bool
        func list() -> [FollowUpQuota]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFollowUpQuotaStore: FollowUpQuotaStore {
        var items: [String: FollowUpQuota]
        var order: [String]

        init(items: [String: FollowUpQuota], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FollowUpQuota? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FollowUpQuota) {
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

        func list() -> [FollowUpQuota] {
            var out: [FollowUpQuota] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFollowUpQuotaStore() -> any FollowUpQuotaStore {
        return MemoryFollowUpQuotaStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFollowUpQuotaStore: FollowUpQuotaStore {
        var inner: MemoryFollowUpQuotaStore
        var cache: TTLCache<FollowUpQuota>
        var hits: Int
        var misses: Int

        init(inner: MemoryFollowUpQuotaStore, cache: TTLCache<FollowUpQuota>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FollowUpQuota? {
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

        func save(_ item: FollowUpQuota) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FollowUpQuota] {
            return inner.list()
        }
    }

    static func newCachedFollowUpQuotaStore(_ inner: MemoryFollowUpQuotaStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FollowUpQuotaStore {
        return CachedFollowUpQuotaStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects follow up quotas. Empty fields match all.
    final class FollowUpQuotaQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FollowUpQuota) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FollowUpQuota]) -> [FollowUpQuota] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FollowUpQuota) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFollowUpQuotas(_ store: any FollowUpQuotaStore, query: FollowUpQuotaQuery) -> [FollowUpQuota] {
        return query.apply(store.list())
    }
}
