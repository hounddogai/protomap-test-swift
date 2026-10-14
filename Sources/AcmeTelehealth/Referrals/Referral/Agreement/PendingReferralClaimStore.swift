import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending referral claims by code.
    protocol PendingReferralClaimStore {
        func find(_ code: String) -> PendingReferralClaim?
        func save(_ item: PendingReferralClaim)
        func remove(_ code: String) -> Bool
        func list() -> [PendingReferralClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingReferralClaimStore: PendingReferralClaimStore {
        var items: [String: PendingReferralClaim]
        var order: [String]

        init(items: [String: PendingReferralClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingReferralClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingReferralClaim) {
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

        func list() -> [PendingReferralClaim] {
            var out: [PendingReferralClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingReferralClaimStore() -> any PendingReferralClaimStore {
        return MemoryPendingReferralClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingReferralClaimStore: PendingReferralClaimStore {
        var inner: MemoryPendingReferralClaimStore
        var cache: TTLCache<PendingReferralClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingReferralClaimStore, cache: TTLCache<PendingReferralClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingReferralClaim? {
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

        func save(_ item: PendingReferralClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingReferralClaim] {
            return inner.list()
        }
    }

    static func newCachedPendingReferralClaimStore(_ inner: MemoryPendingReferralClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingReferralClaimStore {
        return CachedPendingReferralClaimStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending referral claims. Empty fields match all.
    final class PendingReferralClaimQuery {
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

        func matches(_ item: PendingReferralClaim) -> Bool {
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

        func apply(_ items: [PendingReferralClaim]) -> [PendingReferralClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingReferralClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingReferralClaims(_ store: any PendingReferralClaimStore, query: PendingReferralClaimQuery) -> [PendingReferralClaim] {
        return query.apply(store.list())
    }
}
