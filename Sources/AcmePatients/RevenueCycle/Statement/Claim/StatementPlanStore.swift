import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Keeps statement plans by code.
    protocol StatementPlanStore {
        func find(_ code: String) -> StatementPlan?
        func save(_ item: StatementPlan)
        func remove(_ code: String) -> Bool
        func list() -> [StatementPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryStatementPlanStore: StatementPlanStore {
        var items: [String: StatementPlan]
        var order: [String]

        init(items: [String: StatementPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> StatementPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: StatementPlan) {
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

        func list() -> [StatementPlan] {
            var out: [StatementPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryStatementPlanStore() -> any StatementPlanStore {
        return MemoryStatementPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedStatementPlanStore: StatementPlanStore {
        var inner: MemoryStatementPlanStore
        var cache: TTLCache<StatementPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryStatementPlanStore, cache: TTLCache<StatementPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> StatementPlan? {
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

        func save(_ item: StatementPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [StatementPlan] {
            return inner.list()
        }
    }

    static func newCachedStatementPlanStore(_ inner: MemoryStatementPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any StatementPlanStore {
        return CachedStatementPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects statement plans. Empty fields match all.
    final class StatementPlanQuery {
        var channel: String
        var minVisitMinutes: Int
        var statuses: [String]
        var limit: Int

        init(channel: String, minVisitMinutes: Int, statuses: [String], limit: Int) {
            self.channel = channel
            self.minVisitMinutes = minVisitMinutes
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: StatementPlan) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.visitMinutes < minVisitMinutes {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [StatementPlan]) -> [StatementPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: StatementPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findStatementPlans(_ store: any StatementPlanStore, query: StatementPlanQuery) -> [StatementPlan] {
        return query.apply(store.list())
    }
}
