import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps worklist plans by code.
    protocol WorklistPlanStore {
        func find(_ code: String) -> WorklistPlan?
        func save(_ item: WorklistPlan)
        func remove(_ code: String) -> Bool
        func list() -> [WorklistPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryWorklistPlanStore: WorklistPlanStore {
        var items: [String: WorklistPlan]
        var order: [String]

        init(items: [String: WorklistPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> WorklistPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: WorklistPlan) {
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

        func list() -> [WorklistPlan] {
            var out: [WorklistPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryWorklistPlanStore() -> any WorklistPlanStore {
        return MemoryWorklistPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedWorklistPlanStore: WorklistPlanStore {
        var inner: MemoryWorklistPlanStore
        var cache: TTLCache<WorklistPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryWorklistPlanStore, cache: TTLCache<WorklistPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> WorklistPlan? {
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

        func save(_ item: WorklistPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [WorklistPlan] {
            return inner.list()
        }
    }

    static func newCachedWorklistPlanStore(_ inner: MemoryWorklistPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any WorklistPlanStore {
        return CachedWorklistPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects worklist plans. Empty fields match all.
    final class WorklistPlanQuery {
        var title: String
        var minStartsAt: Int
        var statuses: [String]
        var limit: Int

        init(title: String, minStartsAt: Int, statuses: [String], limit: Int) {
            self.title = title
            self.minStartsAt = minStartsAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: WorklistPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.startsAt < minStartsAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [WorklistPlan]) -> [WorklistPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: WorklistPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findWorklistPlans(_ store: any WorklistPlanStore, query: WorklistPlanQuery) -> [WorklistPlan] {
        return query.apply(store.list())
    }
}
