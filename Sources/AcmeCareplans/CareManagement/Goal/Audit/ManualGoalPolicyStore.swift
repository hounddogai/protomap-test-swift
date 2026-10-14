import AcmePlatform
import Foundation

extension CareManagement {
    /// Keeps manual goal policies by code.
    protocol ManualGoalPolicyStore {
        func find(_ code: String) -> ManualGoalPolicy?
        func save(_ item: ManualGoalPolicy)
        func remove(_ code: String) -> Bool
        func list() -> [ManualGoalPolicy]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualGoalPolicyStore: ManualGoalPolicyStore {
        var items: [String: ManualGoalPolicy]
        var order: [String]

        init(items: [String: ManualGoalPolicy], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualGoalPolicy? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualGoalPolicy) {
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

        func list() -> [ManualGoalPolicy] {
            var out: [ManualGoalPolicy] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualGoalPolicyStore() -> any ManualGoalPolicyStore {
        return MemoryManualGoalPolicyStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualGoalPolicyStore: ManualGoalPolicyStore {
        var inner: MemoryManualGoalPolicyStore
        var cache: TTLCache<ManualGoalPolicy>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualGoalPolicyStore, cache: TTLCache<ManualGoalPolicy>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualGoalPolicy? {
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

        func save(_ item: ManualGoalPolicy) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualGoalPolicy] {
            return inner.list()
        }
    }

    static func newCachedManualGoalPolicyStore(_ inner: MemoryManualGoalPolicyStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualGoalPolicyStore {
        return CachedManualGoalPolicyStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual goal policies. Empty fields match all.
    final class ManualGoalPolicyQuery {
        var segment: String
        var minThreshold: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minThreshold: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minThreshold = minThreshold
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualGoalPolicy) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.threshold < minThreshold {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualGoalPolicy]) -> [ManualGoalPolicy] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualGoalPolicy) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualGoalPolicies(_ store: any ManualGoalPolicyStore, query: ManualGoalPolicyQuery) -> [ManualGoalPolicy] {
        return query.apply(store.list())
    }
}
