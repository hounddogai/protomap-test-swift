import AcmePlatform
import Foundation

extension Referrals {
    /// Keeps eligibility groups by code.
    protocol EligibilityGroupStore {
        func find(_ code: String) -> EligibilityGroup?
        func save(_ item: EligibilityGroup)
        func remove(_ code: String) -> Bool
        func list() -> [EligibilityGroup]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryEligibilityGroupStore: EligibilityGroupStore {
        var items: [String: EligibilityGroup]
        var order: [String]

        init(items: [String: EligibilityGroup], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> EligibilityGroup? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: EligibilityGroup) {
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

        func list() -> [EligibilityGroup] {
            var out: [EligibilityGroup] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryEligibilityGroupStore() -> any EligibilityGroupStore {
        return MemoryEligibilityGroupStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedEligibilityGroupStore: EligibilityGroupStore {
        var inner: MemoryEligibilityGroupStore
        var cache: TTLCache<EligibilityGroup>
        var hits: Int
        var misses: Int

        init(inner: MemoryEligibilityGroupStore, cache: TTLCache<EligibilityGroup>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> EligibilityGroup? {
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

        func save(_ item: EligibilityGroup) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [EligibilityGroup] {
            return inner.list()
        }
    }

    static func newCachedEligibilityGroupStore(_ inner: MemoryEligibilityGroupStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any EligibilityGroupStore {
        return CachedEligibilityGroupStore(
            inner: inner,
            cache: newTTLCache(512, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects eligibility groups. Empty fields match all.
    final class EligibilityGroupQuery {
        var unit: String
        var minGraceDays: Int
        var statuses: [String]
        var limit: Int

        init(unit: String, minGraceDays: Int, statuses: [String], limit: Int) {
            self.unit = unit
            self.minGraceDays = minGraceDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: EligibilityGroup) -> Bool {
            if unit != "" && (Kit.Text.normalize(item.unit) != Kit.Text.normalize(unit)) {
                return false
            }
            if item.graceDays < minGraceDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [EligibilityGroup]) -> [EligibilityGroup] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: EligibilityGroup) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findEligibilityGroups(_ store: any EligibilityGroupStore, query: EligibilityGroupQuery) -> [EligibilityGroup] {
        return query.apply(store.list())
    }
}
