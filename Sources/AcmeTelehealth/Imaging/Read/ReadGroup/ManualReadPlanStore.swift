import AcmePlatform
import Foundation

extension Imaging {
    /// Keeps manual read plans by code.
    protocol ManualReadPlanStore {
        func find(_ code: String) -> ManualReadPlan?
        func save(_ item: ManualReadPlan)
        func remove(_ code: String) -> Bool
        func list() -> [ManualReadPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryManualReadPlanStore: ManualReadPlanStore {
        var items: [String: ManualReadPlan]
        var order: [String]

        init(items: [String: ManualReadPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> ManualReadPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: ManualReadPlan) {
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

        func list() -> [ManualReadPlan] {
            var out: [ManualReadPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryManualReadPlanStore() -> any ManualReadPlanStore {
        return MemoryManualReadPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedManualReadPlanStore: ManualReadPlanStore {
        var inner: MemoryManualReadPlanStore
        var cache: TTLCache<ManualReadPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryManualReadPlanStore, cache: TTLCache<ManualReadPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> ManualReadPlan? {
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

        func save(_ item: ManualReadPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [ManualReadPlan] {
            return inner.list()
        }
    }

    static func newCachedManualReadPlanStore(_ inner: MemoryManualReadPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any ManualReadPlanStore {
        return CachedManualReadPlanStore(
            inner: inner,
            cache: newTTLCache(64, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects manual read plans. Empty fields match all.
    final class ManualReadPlanQuery {
        var name: String
        var minUpdatedAt: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minUpdatedAt: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minUpdatedAt = minUpdatedAt
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: ManualReadPlan) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.updatedAt < minUpdatedAt {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [ManualReadPlan]) -> [ManualReadPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: ManualReadPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findManualReadPlans(_ store: any ManualReadPlanStore, query: ManualReadPlanQuery) -> [ManualReadPlan] {
        return query.apply(store.list())
    }
}
