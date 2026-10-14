import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Keeps alert plans by code.
    protocol AlertPlanStore {
        func find(_ code: String) -> AlertPlan?
        func save(_ item: AlertPlan)
        func remove(_ code: String) -> Bool
        func list() -> [AlertPlan]
    }

    /// Keeps records in memory, in the order they were first saved.
    final class MemoryAlertPlanStore: AlertPlanStore {
        var items: [String: AlertPlan]
        var order: [String]

        init(items: [String: AlertPlan], order: [String]) {
            self.items = items
            self.order = order
        }

        func find(_ code: String) -> AlertPlan? {
            guard let found = items[code] else {
                return nil
            }
            return found
        }

        func save(_ item: AlertPlan) {
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

        func list() -> [AlertPlan] {
            var out: [AlertPlan] = []
            for key in order {
                guard let found = items[key] else {
                    continue
                }
                out.append(found)
            }
            return out
        }
    }

    static func newMemoryAlertPlanStore() -> any AlertPlanStore {
        return MemoryAlertPlanStore(items: [:], order: [])
    }

    /// Serves reads from a short-lived cache in front of another store.
    final class CachedAlertPlanStore: AlertPlanStore {
        var inner: MemoryAlertPlanStore
        var cache: TTLCache<AlertPlan>
        var hits: Int
        var misses: Int

        init(inner: MemoryAlertPlanStore, cache: TTLCache<AlertPlan>, hits: Int, misses: Int) {
            self.inner = inner
            self.cache = cache
            self.hits = hits
            self.misses = misses
        }

        func find(_ code: String) -> AlertPlan? {
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

        func save(_ item: AlertPlan) {
            inner.save(item)
            cache.put(item.code, value: item)
        }

        func remove(_ code: String) -> Bool {
            // A cached copy expires on its own; reads after a removal may still see it until then.
            return inner.remove(code)
        }

        func list() -> [AlertPlan] {
            return inner.list()
        }
    }

    static func newCachedAlertPlanStore(_ inner: MemoryAlertPlanStore, ttl: Int, clock: any Kit.Clocks.Clock) -> any AlertPlanStore {
        return CachedAlertPlanStore(
            inner: inner,
            cache: newTTLCache(128, ttl: ttl, clock: clock),
            hits: 0,
            misses: 0
        )
    }

    /// Selects alert plans. Empty fields match all.
    final class AlertPlanQuery {
        var title: String
        var minRate: Double
        var statuses: [String]
        var limit: Int

        init(title: String, minRate: Double, statuses: [String], limit: Int) {
            self.title = title
            self.minRate = minRate
            self.statuses = statuses
            self.limit = limit
        }

        func matches(_ item: AlertPlan) -> Bool {
            if title != "" && (Kit.Text.normalize(item.title) != Kit.Text.normalize(title)) {
                return false
            }
            if item.rate < minRate {
                return false
            }
            if statuses.count > 0 && !statuses.contains("\(item.status.rawValue)") {
                return false
            }
            return true
        }

        func apply(_ items: [AlertPlan]) -> [AlertPlan] {
            let matched = Kit.Collections.filter(items, keep: { (candidate: AlertPlan) -> Bool in return self.matches(candidate) })
            if limit > 0 && (matched.count > limit) {
                return Kit.Collections.take(matched, countValue: limit)
            }
            return matched
        }
    }

    static func findAlertPlans(_ store: any AlertPlanStore, query: AlertPlanQuery) -> [AlertPlan] {
        return query.apply(store.list())
    }
}
