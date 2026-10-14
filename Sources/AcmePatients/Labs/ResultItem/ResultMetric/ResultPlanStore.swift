import AcmePlatform
import Foundation

extension Labs {
    /// Keeps result plans by code.
    protocol ResultPlanStore {
        func find(_ code: String) -> ResultPlan?
        func save(_ item: ResultPlan)
        func remove(_ code: String) -> Bool
        func list() -> [ResultPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryResultPlanStore: ResultPlanStore {
        var items: [String: ResultPlan]
        var order: [String]

        init(items: [String: ResultPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ResultPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ResultPlan) {
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

        func list() -> [ResultPlan] {
            var out: [ResultPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryResultPlanStore() -> any ResultPlanStore {
        return MemoryResultPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedResultPlanStore: ResultPlanStore {
        var inner: MemoryResultPlanStore
        var cache: TTLCache<ResultPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryResultPlanStore, cache: TTLCache<ResultPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ResultPlan? {
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

        func save(_ item: ResultPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ResultPlan] {
            return inner.list()
        }
    }

    static func newCachedResultPlanStore(_ inner: MemoryResultPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ResultPlanStore {
        return CachedResultPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects result plans. Empty fields match all.
    final class ResultPlanQuery {
        var segment: String
        var minAmount: Double
        var statuses: [String]
        var limit: Int

        init(segment: String, minAmount: Double, statuses: [String], limit: Int) {
            self.segment = segment
            self.minAmount = minAmount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ResultPlan) -> Bool {
            if segment != "" && (Kit.Text.normalize(item.segment) != Kit.Text.normalize(segment)) {
                return false
            }
            if item.amount < minAmount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ResultPlan]) -> [ResultPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ResultPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findResultPlans(_ store: any ResultPlanStore, query: ResultPlanQuery) -> [ResultPlan] {
        return query.apply(store.list())
    }
}
