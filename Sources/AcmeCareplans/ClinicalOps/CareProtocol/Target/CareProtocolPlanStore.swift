import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps care protocol plans by code.
    protocol CareProtocolPlanStore {
        func find(_ code: String) -> CareProtocolPlan?
        func save(_ item: CareProtocolPlan)
        func remove(_ code: String) -> Bool
        func list() -> [CareProtocolPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryCareProtocolPlanStore: CareProtocolPlanStore {
        var items: [String: CareProtocolPlan]
        var order: [String]

        init(items: [String: CareProtocolPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> CareProtocolPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: CareProtocolPlan) {
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

        func list() -> [CareProtocolPlan] {
            var out: [CareProtocolPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryCareProtocolPlanStore() -> any CareProtocolPlanStore {
        return MemoryCareProtocolPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedCareProtocolPlanStore: CareProtocolPlanStore {
        var inner: MemoryCareProtocolPlanStore
        var cache: TTLCache<CareProtocolPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryCareProtocolPlanStore, cache: TTLCache<CareProtocolPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> CareProtocolPlan? {
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

        func save(_ item: CareProtocolPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [CareProtocolPlan] {
            return inner.list()
        }
    }

    static func newCachedCareProtocolPlanStore(_ inner: MemoryCareProtocolPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any CareProtocolPlanStore {
        return CachedCareProtocolPlanStore(
            inner: inner,
            cache: newTTLCache(256, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects care protocol plans. Empty fields match all.
    final class CareProtocolPlanQuery {
        var name: String
        var minDiscount: Double
        var statuses: [String]
        var limit: Int

        init(name: String, minDiscount: Double, statuses: [String], limit: Int) {
            self.name = name
            self.minDiscount = minDiscount
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: CareProtocolPlan) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.discount < minDiscount {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [CareProtocolPlan]) -> [CareProtocolPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: CareProtocolPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findCareProtocolPlans(_ store: any CareProtocolPlanStore, query: CareProtocolPlanQuery) -> [CareProtocolPlan] {
        return query.apply(store.list())
    }
}
