import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps scheduled goal policies by code.
    protocol ScheduledGoalPolicyStore {
        func find(_ code: String) -> ScheduledGoalPolicy?
        func save(_ item: ScheduledGoalPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledGoalPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledGoalPolicyStore: ScheduledGoalPolicyStore {
        var items: [String: ScheduledGoalPolicy]
        var order: [String]

        init(items: [String: ScheduledGoalPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledGoalPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledGoalPolicy) {
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

        func list() -> [ScheduledGoalPolicy] {
            var out: [ScheduledGoalPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledGoalPolicyStore() -> any ScheduledGoalPolicyStore {
        return MemoryScheduledGoalPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledGoalPolicyStore: ScheduledGoalPolicyStore {
        var inner: MemoryScheduledGoalPolicyStore
        var cache: TTLCache<ScheduledGoalPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledGoalPolicyStore, cache: TTLCache<ScheduledGoalPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledGoalPolicy? {
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

        func save(_ item: ScheduledGoalPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledGoalPolicy] {
            return inner.list()
        }
    }

    static func newCachedScheduledGoalPolicyStore(_ inner: MemoryScheduledGoalPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledGoalPolicyStore {
        return CachedScheduledGoalPolicyStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled goal policies. Empty fields match all.
    final class ScheduledGoalPolicyQuery {
        var locale: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(locale: String, minRefills: Int, statuses: [String], limit: Int) {
            self.locale = locale
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledGoalPolicy) -> Bool {
            if locale != "" && (Kit.Text.normalize(item.locale) != Kit.Text.normalize(locale)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledGoalPolicy]) -> [ScheduledGoalPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledGoalPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledGoalPolicies(_ store: any ScheduledGoalPolicyStore, query: ScheduledGoalPolicyQuery) -> [ScheduledGoalPolicy] {
        return query.apply(store.list())
    }
}
