import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps primary referral milestones by code.
    protocol PrimaryReferralMilestoneStore {
        func find(_ code: String) -> PrimaryReferralMilestone?
        func save(_ item: PrimaryReferralMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [PrimaryReferralMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryPrimaryReferralMilestoneStore: PrimaryReferralMilestoneStore {
        var items: [String: PrimaryReferralMilestone]
        var order: [String]

        init(items: [String: PrimaryReferralMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> PrimaryReferralMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: PrimaryReferralMilestone) {
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

        func list() -> [PrimaryReferralMilestone] {
            var out: [PrimaryReferralMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryPrimaryReferralMilestoneStore() -> any PrimaryReferralMilestoneStore {
        return MemoryPrimaryReferralMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedPrimaryReferralMilestoneStore: PrimaryReferralMilestoneStore {
        var inner: MemoryPrimaryReferralMilestoneStore
        var cache: TTLCache<PrimaryReferralMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryPrimaryReferralMilestoneStore, cache: TTLCache<PrimaryReferralMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> PrimaryReferralMilestone? {
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

        func save(_ item: PrimaryReferralMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [PrimaryReferralMilestone] {
            return inner.list()
        }
    }

    static func newCachedPrimaryReferralMilestoneStore(_ inner: MemoryPrimaryReferralMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any PrimaryReferralMilestoneStore {
        return CachedPrimaryReferralMilestoneStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects primary referral milestones. Empty fields match all.
    final class PrimaryReferralMilestoneQuery {
        var title: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: PrimaryReferralMilestone) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.attempts < minAttempts {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [PrimaryReferralMilestone]) -> [PrimaryReferralMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: PrimaryReferralMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findPrimaryReferralMilestones(_ store: any PrimaryReferralMilestoneStore, query: PrimaryReferralMilestoneQuery) -> [PrimaryReferralMilestone] {
        return query.apply(store.list())
    }
}
