import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral policies by code.
    protocol ReferralPolicyStore {
        func find(_ code: String) -> ReferralPolicy?
        func save(_ item: ReferralPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralPolicyStore: ReferralPolicyStore {
        var items: [String: ReferralPolicy]
        var order: [String]

        init(items: [String: ReferralPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralPolicy) {
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

        func list() -> [ReferralPolicy] {
            var out: [ReferralPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralPolicyStore() -> any ReferralPolicyStore {
        return MemoryReferralPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralPolicyStore: ReferralPolicyStore {
        var inner: MemoryReferralPolicyStore
        var cache: TTLCache<ReferralPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralPolicyStore, cache: TTLCache<ReferralPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralPolicy? {
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

        func save(_ item: ReferralPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralPolicy] {
            return inner.list()
        }
    }

    static func newCachedReferralPolicyStore(_ inner: MemoryReferralPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralPolicyStore {
        return CachedReferralPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral policies. Empty fields match all.
    final class ReferralPolicyQuery {
        var title: String
        var minBatchSize: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minBatchSize: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minBatchSize = minBatchSize
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralPolicy) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
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

        func apply(_ items: [ReferralPolicy]) -> [ReferralPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralPolicies(_ store: any ReferralPolicyStore, query: ReferralPolicyQuery) -> [ReferralPolicy] {
        return query.apply(store.list())
    }
}
