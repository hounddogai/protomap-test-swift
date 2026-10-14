import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps pending referral milestones by code.
    protocol PendingReferralMilestoneStore {
        func find(_ code: String) -> PendingReferralMilestone?
        func save(_ item: PendingReferralMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [PendingReferralMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPendingReferralMilestoneStore: PendingReferralMilestoneStore {
        var items: [String: PendingReferralMilestone]
        var order: [String]

        init(items: [String: PendingReferralMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PendingReferralMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PendingReferralMilestone) {
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

        func list() -> [PendingReferralMilestone] {
            var out: [PendingReferralMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPendingReferralMilestoneStore() -> any PendingReferralMilestoneStore {
        return MemoryPendingReferralMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPendingReferralMilestoneStore: PendingReferralMilestoneStore {
        var inner: MemoryPendingReferralMilestoneStore
        var cache: TTLCache<PendingReferralMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryPendingReferralMilestoneStore, cache: TTLCache<PendingReferralMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PendingReferralMilestone? {
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

        func save(_ item: PendingReferralMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PendingReferralMilestone] {
            return inner.list()
        }
    }

    static func newCachedPendingReferralMilestoneStore(_ inner: MemoryPendingReferralMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PendingReferralMilestoneStore {
        return CachedPendingReferralMilestoneStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects pending referral milestones. Empty fields match all.
    final class PendingReferralMilestoneQuery {
        var unit: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PendingReferralMilestone) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.expiresAt < minExpiresAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PendingReferralMilestone]) -> [PendingReferralMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PendingReferralMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPendingReferralMilestones(_ store: any PendingReferralMilestoneStore, query: PendingReferralMilestoneQuery) -> [PendingReferralMilestone] {
        return query.apply(store.list())
    }
}
