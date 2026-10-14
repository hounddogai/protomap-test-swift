import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps claim milestones by code.
    protocol ClaimMilestoneStore {
        func find(_ code: String) -> ClaimMilestone?
        func save(_ item: ClaimMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [ClaimMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryClaimMilestoneStore: ClaimMilestoneStore {
        var items: [String: ClaimMilestone]
        var order: [String]

        init(items: [String: ClaimMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ClaimMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ClaimMilestone) {
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

        func list() -> [ClaimMilestone] {
            var out: [ClaimMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryClaimMilestoneStore() -> any ClaimMilestoneStore {
        return MemoryClaimMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedClaimMilestoneStore: ClaimMilestoneStore {
        var inner: MemoryClaimMilestoneStore
        var cache: TTLCache<ClaimMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryClaimMilestoneStore, cache: TTLCache<ClaimMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ClaimMilestone? {
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

        func save(_ item: ClaimMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ClaimMilestone] {
            return inner.list()
        }
    }

    static func newCachedClaimMilestoneStore(_ inner: MemoryClaimMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ClaimMilestoneStore {
        return CachedClaimMilestoneStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects claim milestones. Empty fields match all.
    final class ClaimMilestoneQuery {
        var name: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minMargin: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ClaimMilestone) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
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

        func apply(_ items: [ClaimMilestone]) -> [ClaimMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ClaimMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findClaimMilestones(_ store: any ClaimMilestoneStore, query: ClaimMilestoneQuery) -> [ClaimMilestone] {
        return query.apply(store.list())
    }
}
