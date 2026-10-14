import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps weighted referral proposals by code.
    protocol WeightedReferralProposalStore {
        func find(_ code: String) -> WeightedReferralProposal?
        func save(_ item: WeightedReferralProposal)
        func remove(_ code: String) -> Bool
        func list() -> [WeightedReferralProposal]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWeightedReferralProposalStore: WeightedReferralProposalStore {
        var items: [String: WeightedReferralProposal]
        var order: [String]

        init(items: [String: WeightedReferralProposal], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WeightedReferralProposal? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WeightedReferralProposal) {
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

        func list() -> [WeightedReferralProposal] {
            var out: [WeightedReferralProposal] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWeightedReferralProposalStore() -> any WeightedReferralProposalStore {
        return MemoryWeightedReferralProposalStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWeightedReferralProposalStore: WeightedReferralProposalStore {
        var inner: MemoryWeightedReferralProposalStore
        var cache: TTLCache<WeightedReferralProposal>
        var hits: Int
        var misses: Int

        init(inner: MemoryWeightedReferralProposalStore, cache: TTLCache<WeightedReferralProposal>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WeightedReferralProposal? {
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

        func save(_ item: WeightedReferralProposal) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WeightedReferralProposal] {
            return inner.list()
        }
    }

    static func newCachedWeightedReferralProposalStore(_ inner: MemoryWeightedReferralProposalStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WeightedReferralProposalStore {
        return CachedWeightedReferralProposalStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects weighted referral proposals. Empty fields match all.
    final class WeightedReferralProposalQuery {
        var ward: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(ward: String, minMargin: Double, statuses: [String], limit: Int) {
            self.ward = ward
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WeightedReferralProposal) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WeightedReferralProposal]) -> [WeightedReferralProposal] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WeightedReferralProposal) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWeightedReferralProposals(_ store: any WeightedReferralProposalStore, query: WeightedReferralProposalQuery) -> [WeightedReferralProposal] {
        return query.apply(store.list())
    }
}
