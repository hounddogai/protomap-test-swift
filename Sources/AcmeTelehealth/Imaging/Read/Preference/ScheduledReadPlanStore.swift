import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps scheduled read plans by code.
    protocol ScheduledReadPlanStore {
        func find(_ code: String) -> ScheduledReadPlan?
        func save(_ item: ScheduledReadPlan)
        func remove(_ code: String) -> Bool
        func list() -> [ScheduledReadPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryScheduledReadPlanStore: ScheduledReadPlanStore {
        var items: [String: ScheduledReadPlan]
        var order: [String]

        init(items: [String: ScheduledReadPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ScheduledReadPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ScheduledReadPlan) {
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

        func list() -> [ScheduledReadPlan] {
            var out: [ScheduledReadPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryScheduledReadPlanStore() -> any ScheduledReadPlanStore {
        return MemoryScheduledReadPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedScheduledReadPlanStore: ScheduledReadPlanStore {
        var inner: MemoryScheduledReadPlanStore
        var cache: TTLCache<ScheduledReadPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryScheduledReadPlanStore, cache: TTLCache<ScheduledReadPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ScheduledReadPlan? {
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

        func save(_ item: ScheduledReadPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ScheduledReadPlan] {
            return inner.list()
        }
    }

    static func newCachedScheduledReadPlanStore(_ inner: MemoryScheduledReadPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ScheduledReadPlanStore {
        return CachedScheduledReadPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects scheduled read plans. Empty fields match all.
    final class ScheduledReadPlanQuery {
        var title: String
        var minQuantity: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minQuantity: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minQuantity = minQuantity
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ScheduledReadPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.quantity < minQuantity {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ScheduledReadPlan]) -> [ScheduledReadPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ScheduledReadPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findScheduledReadPlans(_ store: any ScheduledReadPlanStore, query: ScheduledReadPlanQuery) -> [ScheduledReadPlan] {
        return query.apply(store.list())
    }
}
