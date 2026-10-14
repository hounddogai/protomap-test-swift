import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps strict denial milestones by code.
    protocol StrictDenialMilestoneStore {
        func find(_ code: String) -> StrictDenialMilestone?
        func save(_ item: StrictDenialMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [StrictDenialMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStrictDenialMilestoneStore: StrictDenialMilestoneStore {
        var items: [String: StrictDenialMilestone]
        var order: [String]

        init(items: [String: StrictDenialMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StrictDenialMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StrictDenialMilestone) {
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

        func list() -> [StrictDenialMilestone] {
            var out: [StrictDenialMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStrictDenialMilestoneStore() -> any StrictDenialMilestoneStore {
        return MemoryStrictDenialMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStrictDenialMilestoneStore: StrictDenialMilestoneStore {
        var inner: MemoryStrictDenialMilestoneStore
        var cache: TTLCache<StrictDenialMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryStrictDenialMilestoneStore, cache: TTLCache<StrictDenialMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StrictDenialMilestone? {
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

        func save(_ item: StrictDenialMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StrictDenialMilestone] {
            return inner.list()
        }
    }

    static func newCachedStrictDenialMilestoneStore(_ inner: MemoryStrictDenialMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StrictDenialMilestoneStore {
        return CachedStrictDenialMilestoneStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects strict denial milestones. Empty fields match all.
    final class StrictDenialMilestoneQuery {
        var ward: String
        var minExpiresAt: Int
        var statuses: [String]
        var limit: Int

        init(ward: String, minExpiresAt: Int, statuses: [String], limit: Int) {
            self.ward = ward
            self.minExpiresAt = minExpiresAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StrictDenialMilestone) -> Bool {
            if ward != "" && (Kit.Text.normalize(item.ward) != Kit.Text.normalize(ward)) {
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

        func apply(_ items: [StrictDenialMilestone]) -> [StrictDenialMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StrictDenialMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStrictDenialMilestones(_ store: any StrictDenialMilestoneStore, query: StrictDenialMilestoneQuery) -> [StrictDenialMilestone] {
        return query.apply(store.list())
    }
}
