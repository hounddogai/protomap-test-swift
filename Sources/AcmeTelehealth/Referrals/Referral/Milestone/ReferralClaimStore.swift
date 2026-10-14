import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral claims by code.
    protocol ReferralClaimStore {
        func find(_ code: String) -> ReferralClaim?
        func save(_ item: ReferralClaim)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralClaimStore: ReferralClaimStore {
        var items: [String: ReferralClaim]
        var order: [String]

        init(items: [String: ReferralClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralClaim) {
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

        func list() -> [ReferralClaim] {
            var out: [ReferralClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralClaimStore() -> any ReferralClaimStore {
        return MemoryReferralClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralClaimStore: ReferralClaimStore {
        var inner: MemoryReferralClaimStore
        var cache: TTLCache<ReferralClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralClaimStore, cache: TTLCache<ReferralClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralClaim? {
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

        func save(_ item: ReferralClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralClaim] {
            return inner.list()
        }
    }

    static func newCachedReferralClaimStore(_ inner: MemoryReferralClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralClaimStore {
        return CachedReferralClaimStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral claims. Empty fields match all.
    final class ReferralClaimQuery {
        var channel: String
        var minCapacity: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minCapacity: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minCapacity = minCapacity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralClaim) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.capacity < minCapacity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralClaim]) -> [ReferralClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralClaims(_ store: any ReferralClaimStore, query: ReferralClaimQuery) -> [ReferralClaim] {
        return query.apply(store.list())
    }
}
