import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps adaptive referral claims by code.
    protocol AdaptiveReferralClaimStore {
        func find(_ code: String) -> AdaptiveReferralClaim?
        func save(_ item: AdaptiveReferralClaim)
        func remove(_ code: String) -> Bool
        func list() -> [AdaptiveReferralClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAdaptiveReferralClaimStore: AdaptiveReferralClaimStore {
        var items: [String: AdaptiveReferralClaim]
        var order: [String]

        init(items: [String: AdaptiveReferralClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AdaptiveReferralClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AdaptiveReferralClaim) {
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

        func list() -> [AdaptiveReferralClaim] {
            var out: [AdaptiveReferralClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAdaptiveReferralClaimStore() -> any AdaptiveReferralClaimStore {
        return MemoryAdaptiveReferralClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAdaptiveReferralClaimStore: AdaptiveReferralClaimStore {
        var inner: MemoryAdaptiveReferralClaimStore
        var cache: TTLCache<AdaptiveReferralClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryAdaptiveReferralClaimStore, cache: TTLCache<AdaptiveReferralClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AdaptiveReferralClaim? {
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

        func save(_ item: AdaptiveReferralClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AdaptiveReferralClaim] {
            return inner.list()
        }
    }

    static func newCachedAdaptiveReferralClaimStore(_ inner: MemoryAdaptiveReferralClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AdaptiveReferralClaimStore {
        return CachedAdaptiveReferralClaimStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects adaptive referral claims. Empty fields match all.
    final class AdaptiveReferralClaimQuery {
        var unit: String
        var minSequence: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minSequence: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minSequence = minSequence
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AdaptiveReferralClaim) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.sequence < minSequence {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AdaptiveReferralClaim]) -> [AdaptiveReferralClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AdaptiveReferralClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAdaptiveReferralClaims(_ store: any AdaptiveReferralClaimStore, query: AdaptiveReferralClaimQuery) -> [AdaptiveReferralClaim] {
        return query.apply(store.list())
    }
}
