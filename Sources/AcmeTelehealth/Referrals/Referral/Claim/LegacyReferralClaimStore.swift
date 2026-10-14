import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps legacy referral claims by code.
    protocol LegacyReferralClaimStore {
        func find(_ code: String) -> LegacyReferralClaim?
        func save(_ item: LegacyReferralClaim)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyReferralClaim]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyReferralClaimStore: LegacyReferralClaimStore {
        var items: [String: LegacyReferralClaim]
        var order: [String]

        init(items: [String: LegacyReferralClaim], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyReferralClaim? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyReferralClaim) {
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

        func list() -> [LegacyReferralClaim] {
            var out: [LegacyReferralClaim] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyReferralClaimStore() -> any LegacyReferralClaimStore {
        return MemoryLegacyReferralClaimStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyReferralClaimStore: LegacyReferralClaimStore {
        var inner: MemoryLegacyReferralClaimStore
        var cache: TTLCache<LegacyReferralClaim>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyReferralClaimStore, cache: TTLCache<LegacyReferralClaim>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyReferralClaim? {
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

        func save(_ item: LegacyReferralClaim) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyReferralClaim] {
            return inner.list()
        }
    }

    static func newCachedLegacyReferralClaimStore(_ inner: MemoryLegacyReferralClaimStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyReferralClaimStore {
        return CachedLegacyReferralClaimStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy referral claims. Empty fields match all.
    final class LegacyReferralClaimQuery {
        var unit: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minRefills: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyReferralClaim) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
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

        func apply(_ items: [LegacyReferralClaim]) -> [LegacyReferralClaim] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyReferralClaim) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyReferralClaims(_ store: any LegacyReferralClaimStore, query: LegacyReferralClaimQuery) -> [LegacyReferralClaim] {
        return query.apply(store.list())
    }
}
