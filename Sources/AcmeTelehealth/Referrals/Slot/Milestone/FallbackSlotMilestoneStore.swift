import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps fallback slot milestones by code.
    protocol FallbackSlotMilestoneStore {
        func find(_ code: String) -> FallbackSlotMilestone?
        func save(_ item: FallbackSlotMilestone)
        func remove(_ code: String) -> Bool
        func list() -> [FallbackSlotMilestone]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryFallbackSlotMilestoneStore: FallbackSlotMilestoneStore {
        var items: [String: FallbackSlotMilestone]
        var order: [String]

        init(items: [String: FallbackSlotMilestone], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> FallbackSlotMilestone? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: FallbackSlotMilestone) {
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

        func list() -> [FallbackSlotMilestone] {
            var out: [FallbackSlotMilestone] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryFallbackSlotMilestoneStore() -> any FallbackSlotMilestoneStore {
        return MemoryFallbackSlotMilestoneStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedFallbackSlotMilestoneStore: FallbackSlotMilestoneStore {
        var inner: MemoryFallbackSlotMilestoneStore
        var cache: TTLCache<FallbackSlotMilestone>
        var hits: Int
        var misses: Int

        init(inner: MemoryFallbackSlotMilestoneStore, cache: TTLCache<FallbackSlotMilestone>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> FallbackSlotMilestone? {
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

        func save(_ item: FallbackSlotMilestone) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [FallbackSlotMilestone] {
            return inner.list()
        }
    }

    static func newCachedFallbackSlotMilestoneStore(_ inner: MemoryFallbackSlotMilestoneStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any FallbackSlotMilestoneStore {
        return CachedFallbackSlotMilestoneStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects fallback slot milestones. Empty fields match all.
    final class FallbackSlotMilestoneQuery {
        var country: String
        var minCeiling: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minCeiling: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minCeiling = minCeiling
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: FallbackSlotMilestone) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.ceiling < minCeiling {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [FallbackSlotMilestone]) -> [FallbackSlotMilestone] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: FallbackSlotMilestone) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findFallbackSlotMilestones(_ store: any FallbackSlotMilestoneStore, query: FallbackSlotMilestoneQuery) -> [FallbackSlotMilestone] {
        return query.apply(store.list())
    }
}
