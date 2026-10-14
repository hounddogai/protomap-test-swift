import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps goal policies by code.
    protocol GoalPolicyStore {
        func find(_ code: String) -> GoalPolicy?
        func save(_ item: GoalPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [GoalPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGoalPolicyStore: GoalPolicyStore {
        var items: [String: GoalPolicy]
        var order: [String]

        init(items: [String: GoalPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GoalPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GoalPolicy) {
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

        func list() -> [GoalPolicy] {
            var out: [GoalPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGoalPolicyStore() -> any GoalPolicyStore {
        return MemoryGoalPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGoalPolicyStore: GoalPolicyStore {
        var inner: MemoryGoalPolicyStore
        var cache: TTLCache<GoalPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryGoalPolicyStore, cache: TTLCache<GoalPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GoalPolicy? {
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

        func save(_ item: GoalPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GoalPolicy] {
            return inner.list()
        }
    }

    static func newCachedGoalPolicyStore(_ inner: MemoryGoalPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GoalPolicyStore {
        return CachedGoalPolicyStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects goal policies. Empty fields match all.
    final class GoalPolicyQuery {
        var country: String
        var minFloorValue: Double
        var statuses: [String]
        var limit: Int

        init(country: String, minFloorValue: Double, statuses: [String], limit: Int) {
            self.country = country
            self.minFloorValue = minFloorValue
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GoalPolicy) -> Bool {
            if country != "" && (Kit.Text.normalize(item.country) != Kit.Text.normalize(country)) {
                return false
            }
            if item.floorValue < minFloorValue {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GoalPolicy]) -> [GoalPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GoalPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGoalPolicies(_ store: any GoalPolicyStore, query: GoalPolicyQuery) -> [GoalPolicy] {
        return query.apply(store.list())
    }
}
