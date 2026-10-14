import AcmePlatform
import Foundation

extension Consent {
    /// Keeps global consent form plans by code.
    protocol GlobalConsentFormPlanStore {
        func find(_ code: String) -> GlobalConsentFormPlan?
        func save(_ item: GlobalConsentFormPlan)
        func remove(_ code: String) -> Bool
        func list() -> [GlobalConsentFormPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryGlobalConsentFormPlanStore: GlobalConsentFormPlanStore {
        var items: [String: GlobalConsentFormPlan]
        var order: [String]

        init(items: [String: GlobalConsentFormPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> GlobalConsentFormPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: GlobalConsentFormPlan) {
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

        func list() -> [GlobalConsentFormPlan] {
            var out: [GlobalConsentFormPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryGlobalConsentFormPlanStore() -> any GlobalConsentFormPlanStore {
        return MemoryGlobalConsentFormPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedGlobalConsentFormPlanStore: GlobalConsentFormPlanStore {
        var inner: MemoryGlobalConsentFormPlanStore
        var cache: TTLCache<GlobalConsentFormPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryGlobalConsentFormPlanStore, cache: TTLCache<GlobalConsentFormPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> GlobalConsentFormPlan? {
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

        func save(_ item: GlobalConsentFormPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [GlobalConsentFormPlan] {
            return inner.list()
        }
    }

    static func newCachedGlobalConsentFormPlanStore(_ inner: MemoryGlobalConsentFormPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any GlobalConsentFormPlanStore {
        return CachedGlobalConsentFormPlanStore(
            inner: inner,
            cache: newTTLCache(1024, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects global consent form plans. Empty fields match all.
    final class GlobalConsentFormPlanQuery {
        var name: String
        var minRefills: Int
        var statuses: [String]
        var limit: Int

        init(name: String, minRefills: Int, statuses: [String], limit: Int) {
            self.name = name
            self.minRefills = minRefills
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: GlobalConsentFormPlan) -> Bool {
            if name != "" && (Kit.Text.normalize(item.name) != Kit.Text.normalize(name)) {
                return false
            }
            if item.refills < minRefills {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [GlobalConsentFormPlan]) -> [GlobalConsentFormPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: GlobalConsentFormPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findGlobalConsentFormPlans(_ store: any GlobalConsentFormPlanStore, query: GlobalConsentFormPlanQuery) -> [GlobalConsentFormPlan] {
        return query.apply(store.list())
    }
}
