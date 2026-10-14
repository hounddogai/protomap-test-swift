import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps legacy statement plans by code.
    protocol LegacyStatementPlanStore {
        func find(_ code: String) -> LegacyStatementPlan?
        func save(_ item: LegacyStatementPlan)
        func remove(_ code: String) -> Bool
        func list() -> [LegacyStatementPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLegacyStatementPlanStore: LegacyStatementPlanStore {
        var items: [String: LegacyStatementPlan]
        var order: [String]

        init(items: [String: LegacyStatementPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LegacyStatementPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LegacyStatementPlan) {
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

        func list() -> [LegacyStatementPlan] {
            var out: [LegacyStatementPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLegacyStatementPlanStore() -> any LegacyStatementPlanStore {
        return MemoryLegacyStatementPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLegacyStatementPlanStore: LegacyStatementPlanStore {
        var inner: MemoryLegacyStatementPlanStore
        var cache: TTLCache<LegacyStatementPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryLegacyStatementPlanStore, cache: TTLCache<LegacyStatementPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LegacyStatementPlan? {
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

        func save(_ item: LegacyStatementPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LegacyStatementPlan] {
            return inner.list()
        }
    }

    static func newCachedLegacyStatementPlanStore(_ inner: MemoryLegacyStatementPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LegacyStatementPlanStore {
        return CachedLegacyStatementPlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects legacy statement plans. Empty fields match all.
    final class LegacyStatementPlanQuery {
        var label: String
        var minAttempts: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minAttempts: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minAttempts = minAttempts
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LegacyStatementPlan) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
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

        func apply(_ items: [LegacyStatementPlan]) -> [LegacyStatementPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LegacyStatementPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLegacyStatementPlans(_ store: any LegacyStatementPlanStore, query: LegacyStatementPlanQuery) -> [LegacyStatementPlan] {
        return query.apply(store.list())
    }
}
