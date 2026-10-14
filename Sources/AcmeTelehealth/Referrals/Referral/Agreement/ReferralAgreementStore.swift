import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral agreements by code.
    protocol ReferralAgreementStore {
        func find(_ code: String) -> ReferralAgreement?
        func save(_ item: ReferralAgreement)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralAgreement]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralAgreementStore: ReferralAgreementStore {
        var items: [String: ReferralAgreement]
        var order: [String]

        init(items: [String: ReferralAgreement], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralAgreement? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralAgreement) {
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

        func list() -> [ReferralAgreement] {
            var out: [ReferralAgreement] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralAgreementStore() -> any ReferralAgreementStore {
        return MemoryReferralAgreementStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralAgreementStore: ReferralAgreementStore {
        var inner: MemoryReferralAgreementStore
        var cache: TTLCache<ReferralAgreement>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralAgreementStore, cache: TTLCache<ReferralAgreement>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralAgreement? {
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

        func save(_ item: ReferralAgreement) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralAgreement] {
            return inner.list()
        }
    }

    static func newCachedReferralAgreementStore(_ inner: MemoryReferralAgreementStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralAgreementStore {
        return CachedReferralAgreementStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral agreements. Empty fields match all.
    final class ReferralAgreementQuery {
        var country: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralAgreement) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralAgreement]) -> [ReferralAgreement] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralAgreement) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralAgreements(_ store: any ReferralAgreementStore, query: ReferralAgreementQuery) -> [ReferralAgreement] {
        return query.apply(store.list())
    }
}
