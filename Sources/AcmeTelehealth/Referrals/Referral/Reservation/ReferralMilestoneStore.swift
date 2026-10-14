import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps referral milestones by code.
    protocol ReferralMilestoneStore {
        func find(_ code: String) -> ReferralMilestone?
        func save(_ item: ReferralMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ReferralMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryReferralMilestoneStore: ReferralMilestoneStore {
        var items: [String: ReferralMilestone]
        var order: [String]

        init(items: [String: ReferralMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ReferralMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ReferralMilestone) {
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

        func list() -> [ReferralMilestone] {
            var out: [ReferralMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryReferralMilestoneStore() -> any ReferralMilestoneStore {
        return MemoryReferralMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedReferralMilestoneStore: ReferralMilestoneStore {
        var inner: MemoryReferralMilestoneStore
        var cache: TTLCache<ReferralMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryReferralMilestoneStore, cache: TTLCache<ReferralMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ReferralMilestone? {
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

        func save(_ item: ReferralMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ReferralMilestone] {
            return inner.list()
        }
    }

    static func newCachedReferralMilestoneStore(_ inner: MemoryReferralMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ReferralMilestoneStore {
        return CachedReferralMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects referral milestones. Empty fields match all.
    final class ReferralMilestoneQuery {
        var country: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(country: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.country = country
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ReferralMilestone) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ReferralMilestone]) -> [ReferralMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ReferralMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findReferralMilestones(_ store: any ReferralMilestoneStore, query: ReferralMilestoneQuery) -> [ReferralMilestone] {
        return query.apply(store.list())
    }
}
