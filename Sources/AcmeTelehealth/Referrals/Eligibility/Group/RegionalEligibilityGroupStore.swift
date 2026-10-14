import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps regional eligibility groups by code.
    protocol RegionalEligibilityGroupStore {
        func find(_ code: String) -> RegionalEligibilityGroup?
        func save(_ item: RegionalEligibilityGroup)
        func remove(_ code: String) -> Bool
        func list() -> [RegionalEligibilityGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryRegionalEligibilityGroupStore: RegionalEligibilityGroupStore {
        var items: [String: RegionalEligibilityGroup]
        var order: [String]

        init(items: [String: RegionalEligibilityGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> RegionalEligibilityGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: RegionalEligibilityGroup) {
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

        func list() -> [RegionalEligibilityGroup] {
            var out: [RegionalEligibilityGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryRegionalEligibilityGroupStore() -> any RegionalEligibilityGroupStore {
        return MemoryRegionalEligibilityGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedRegionalEligibilityGroupStore: RegionalEligibilityGroupStore {
        var inner: MemoryRegionalEligibilityGroupStore
        var cache: TTLCache<RegionalEligibilityGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryRegionalEligibilityGroupStore, cache: TTLCache<RegionalEligibilityGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> RegionalEligibilityGroup? {
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

        func save(_ item: RegionalEligibilityGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [RegionalEligibilityGroup] {
            return inner.list()
        }
    }

    static func newCachedRegionalEligibilityGroupStore(_ inner: MemoryRegionalEligibilityGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any RegionalEligibilityGroupStore {
        return CachedRegionalEligibilityGroupStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects regional eligibility groups. Empty fields match all.
    final class RegionalEligibilityGroupQuery {
        var category: String
        var minScore: Double
        var statuses: [String]
        var limit: Int

        init(category: String, minScore: Double, statuses: [String], limit: Int) {
            self.category = category
            self.minScore = minScore
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: RegionalEligibilityGroup) -> Bool {
            if category != "" && (Kit.Text.normalize(item.category) != Kit.Text.normalize(category)) {
                return false
            }
            if item.score < minScore {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [RegionalEligibilityGroup]) -> [RegionalEligibilityGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: RegionalEligibilityGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findRegionalEligibilityGroups(_ store: any RegionalEligibilityGroupStore, query: RegionalEligibilityGroupQuery) -> [RegionalEligibilityGroup] {
        return query.apply(store.list())
    }
}
