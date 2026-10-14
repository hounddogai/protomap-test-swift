import AcmePlatform
import Foundation

extension Pharmacy {
    /// Keeps lenient inventory plans by code.
    protocol LenientInventoryPlanStore {
        func find(_ code: String) -> LenientInventoryPlan?
        func save(_ item: LenientInventoryPlan)
        func remove(_ code: String) -> Bool
        func list() -> [LenientInventoryPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryLenientInventoryPlanStore: LenientInventoryPlanStore {
        var items: [String: LenientInventoryPlan]
        var order: [String]

        init(items: [String: LenientInventoryPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> LenientInventoryPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: LenientInventoryPlan) {
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

        func list() -> [LenientInventoryPlan] {
            var out: [LenientInventoryPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryLenientInventoryPlanStore() -> any LenientInventoryPlanStore {
        return MemoryLenientInventoryPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedLenientInventoryPlanStore: LenientInventoryPlanStore {
        var inner: MemoryLenientInventoryPlanStore
        var cache: TTLCache<LenientInventoryPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryLenientInventoryPlanStore, cache: TTLCache<LenientInventoryPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> LenientInventoryPlan? {
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

        func save(_ item: LenientInventoryPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [LenientInventoryPlan] {
            return inner.list()
        }
    }

    static func newCachedLenientInventoryPlanStore(_ inner: MemoryLenientInventoryPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any LenientInventoryPlanStore {
        return CachedLenientInventoryPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects lenient inventory plans. Empty fields match all.
    final class LenientInventoryPlanQuery {
        var label: String
        var minWindowDays: Int
        var statuses: [String]
        var limit: Int

        init(label: String, minWindowDays: Int, statuses: [String], limit: Int) {
            self.label = label
            self.minWindowDays = minWindowDays
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: LenientInventoryPlan) -> Bool {
            if label != "" && (Kit.Text.normalize(item.label) != Kit.Text.normalize(label)) {
                return false
            }
            if item.windowDays < minWindowDays {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [LenientInventoryPlan]) -> [LenientInventoryPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: LenientInventoryPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findLenientInventoryPlans(_ store: any LenientInventoryPlanStore, query: LenientInventoryPlanQuery) -> [LenientInventoryPlan] {
        return query.apply(store.list())
    }
}
