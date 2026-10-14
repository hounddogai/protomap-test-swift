import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps capped order set plans by code.
    protocol CappedOrderSetPlanStore {
        func find(_ code: String) -> CappedOrderSetPlan?
        func save(_ item: CappedOrderSetPlan)
        func remove(_ code: String) -> Bool
        func list() -> [CappedOrderSetPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCappedOrderSetPlanStore: CappedOrderSetPlanStore {
        var items: [String: CappedOrderSetPlan]
        var order: [String]

        init(items: [String: CappedOrderSetPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CappedOrderSetPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CappedOrderSetPlan) {
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

        func list() -> [CappedOrderSetPlan] {
            var out: [CappedOrderSetPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCappedOrderSetPlanStore() -> any CappedOrderSetPlanStore {
        return MemoryCappedOrderSetPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCappedOrderSetPlanStore: CappedOrderSetPlanStore {
        var inner: MemoryCappedOrderSetPlanStore
        var cache: TTLCache<CappedOrderSetPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryCappedOrderSetPlanStore, cache: TTLCache<CappedOrderSetPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CappedOrderSetPlan? {
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

        func save(_ item: CappedOrderSetPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CappedOrderSetPlan] {
            return inner.list()
        }
    }

    static func newCachedCappedOrderSetPlanStore(_ inner: MemoryCappedOrderSetPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CappedOrderSetPlanStore {
        return CachedCappedOrderSetPlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects capped order set plans. Empty fields match all.
    final class CappedOrderSetPlanQuery {
        var channel: String
        var minMargin: Double
        var statuses: [String]
        var limit: Int

        init(channel: String, minMargin: Double, statuses: [String], limit: Int) {
            self.channel = channel
            self.minMargin = minMargin
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CappedOrderSetPlan) -> Bool {
            if channel != "" && (Kit.Text.normalize(item.channel) != Kit.Text.normalize(channel)) {
                return false
            }
            if item.margin < minMargin {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CappedOrderSetPlan]) -> [CappedOrderSetPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CappedOrderSetPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCappedOrderSetPlans(_ store: any CappedOrderSetPlanStore, query: CappedOrderSetPlanQuery) -> [CappedOrderSetPlan] {
        return query.apply(store.list())
    }
}
