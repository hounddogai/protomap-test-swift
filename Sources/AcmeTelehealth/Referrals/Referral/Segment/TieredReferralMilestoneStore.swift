import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps tiered referral milestones by code.
    protocol TieredReferralMilestoneStore {
        func find(_ code: String) -> TieredReferralMilestone?
        func save(_ item: TieredReferralMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [TieredReferralMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryTieredReferralMilestoneStore: TieredReferralMilestoneStore {
        var items: [String: TieredReferralMilestone]
        var order: [String]

        init(items: [String: TieredReferralMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> TieredReferralMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: TieredReferralMilestone) {
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

        func list() -> [TieredReferralMilestone] {
            var out: [TieredReferralMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryTieredReferralMilestoneStore() -> any TieredReferralMilestoneStore {
        return MemoryTieredReferralMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedTieredReferralMilestoneStore: TieredReferralMilestoneStore {
        var inner: MemoryTieredReferralMilestoneStore
        var cache: TTLCache<TieredReferralMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryTieredReferralMilestoneStore, cache: TTLCache<TieredReferralMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> TieredReferralMilestone? {
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

        func save(_ item: TieredReferralMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [TieredReferralMilestone] {
            return inner.list()
        }
    }

    static func newCachedTieredReferralMilestoneStore(_ inner: MemoryTieredReferralMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any TieredReferralMilestoneStore {
        return CachedTieredReferralMilestoneStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects tiered referral milestones. Empty fields match all.
    final class TieredReferralMilestoneQuery {
        var title: String
        var minMaximum: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minMaximum: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minMaximum = minMaximum
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: TieredReferralMilestone) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.maximum < minMaximum {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [TieredReferralMilestone]) -> [TieredReferralMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: TieredReferralMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findTieredReferralMilestones(_ store: any TieredReferralMilestoneStore, query: TieredReferralMilestoneQuery) -> [TieredReferralMilestone] {
        return query.apply(store.list())
    }
}
